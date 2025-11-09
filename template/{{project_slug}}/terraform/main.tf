locals {
  project_name = "k3s-cluster"
  environment  = "prod"
  managed_by   = "terraform"

  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = local.managed_by
  }

  k3s_primary_control_plane_ip = cidrhost(var.k3s_subnet_cidr, 10)
}

resource "hcloud_ssh_key" "my_ssh_key" {
  name       = "${local.project_name}-${var.ssh_user}"
  public_key = var.ssh_pub_key
}

resource "random_id" "k3s_token" {
  byte_length = 24
}

resource "hcloud_network" "k3s" {
  name     = "${local.project_name}-network"
  ip_range = var.hcloud_network_cidr
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.k3s_subnet_cidr
}

# Firewall with Labels
resource "hcloud_firewall" "k3s_firewall" {
  name   = "${local.project_name}-firewall"
  labels = local.common_labels

  rule {
    description = "Allow ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow Kube API (External Access)"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow Node-to-Node Communication"
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    source_ips  = ["10.115.1.0/24"]
  }
}

resource "hcloud_server" "k3s_control_plane" {
  name        = "${local.project_name}-control-plane-${format("%02d", count.index + 1)}"
  count       = var.k3s_control_plane_node_count
  server_type = var.k3s_control_plane_node_type
  image       = var.k3s_control_plane_node_image
  location    = var.hcloud_datacenter
  labels      = merge(local.common_labels, { role = "control-plane" })

  user_data = templatefile("${path.module}/cloud-init/k3s-control-plane.tftpl", {
    ssh_user                 = var.ssh_user
    ssh_key                  = var.ssh_pub_key
    node_token               = random_id.k3s_token.hex
    is_primary_control_plane = count.index == 0 ? true : false
    hostname                 = "${local.project_name}-control-plane-${format("%02d", count.index + 1)}",
    primary_control_plane_ip = local.k3s_primary_control_plane_ip
  })

  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(var.k3s_subnet_cidr, 10 + count.index)
  }

  lifecycle {
    ignore_changes = [network, user_data]
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 10; done"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_priv_key_file)
      host        = self.ipv4_address
    }
  }
}

resource "hcloud_server" "k3s_worker" {
  name        = "${local.project_name}-worker-${format("%02d", count.index + 1)}"
  count       = var.k3s_worker_node_count
  server_type = var.k3s_worker_node_type
  image       = var.k3s_worker_node_image
  location    = var.hcloud_datacenter
  labels      = merge(local.common_labels, { role = "worker" })

  user_data = templatefile("${path.module}/cloud-init/k3s-agent-node.tftpl", {
    ssh_user         = var.ssh_user
    ssh_key          = var.ssh_pub_key
    node_token       = random_id.k3s_token.hex
    control_plane_ip = local.k3s_primary_control_plane_ip
    hostname         = "${local.project_name}-worker-${format("%02d", count.index + 1)}"
  })

  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  network {
    network_id = hcloud_network.k3s.id
    ip         = "10.115.1.${20 + count.index}"
  }

  lifecycle {
    ignore_changes = [network, user_data]
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 10; done"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_priv_key_file)
      host        = self.ipv4_address
    }
  }
}

# Fetch Kubeconfig for External Access
resource "null_resource" "k3s_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      scp -o StrictHostKeyChecking=no -i ${var.ssh_priv_key_file} ${var.ssh_user}@${hcloud_server.k3s_control_plane[0].ipv4_address}:/etc/rancher/k3s/k3s.yaml ../k3s-kubeconfig.yaml
      sed -i 's|server: https://.*|server: https://${hcloud_server.k3s_control_plane[0].ipv4_address}:6443|' ../k3s-kubeconfig.yaml
      chmod 644 ../k3s-kubeconfig.yaml
    EOT
  }

  depends_on = [hcloud_server.k3s_control_plane]
}

resource "cloudflare_dns_record" "podinfo" {
  zone_id = var.cloudflare_zone_id
  content = hcloud_server.k3s_control_plane[0].ipv4_address
  name    = "podinfo.${var.cloudflare_domain}"
  proxied = true
  settings = {
    ipv4_only = true
    ipv6_only = true
  }
  tags = ["owner:dns-team"]
  ttl  = 3600
  type = "A"
}

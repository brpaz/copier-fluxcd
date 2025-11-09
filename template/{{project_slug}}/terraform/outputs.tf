output "primary_control_plane_ip" {
  value = hcloud_server.k3s_control_plane[0].ipv4_address
}

output "worker_ips" {
  value = hcloud_server.k3s_worker[*].ipv4_address
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "hcloud_datacenter" {
  description = "The Hetzner Cloud datacenter where resources will be created"
  type        = string
  default     = "nbg1"
}

variable "hcloud_network_zone" {
  description = "The Hetzner Cloud network where resources will be created"
  type        = string
  default     = "eu-central"
}

variable "hcloud_network_cidr" {
  description = "The CIDR range for the main network"
  type        = string
  default     = "10.115.0.0/16"
}

variable "k3s_subnet_cidr" {
  description = "The CIDR range for the K3s subnet"
  type        = string
  default     = "10.115.1.0/24"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "k3s-cluster"
}



variable "k3s_control_plane_node_count" {
  description = "The number of control plane nodes"
  type        = number
  default     = 1
}

variable "k3s_control_plane_node_type" {
  description = "The server type for the control plane nodes"
  type        = string
  default     = "cx22"
}

variable "k3s_control_plane_node_image" {
  description = "The image to use for the VM instance"
  type        = string
  default     = "ubuntu-24.04"
}

variable "k3s_worker_node_type" {
  description = "The server type for the worker nodes"
  type        = string
  default     = "cx22"
}

variable "k3s_worker_node_image" {
  description = "The image to use for the VM instance"
  type        = string
  default     = "ubuntu-24.04"
}

variable "k3s_worker_node_count" {
  description = "The number of worker nodes"
  type        = number
  default     = 0
}

variable "ssh_user" {
  description = "SSH user for the VM instance"
  type        = string
  default     = "bruno"
}

variable "ssh_pub_key" {
  description = "SSH public key for the VM instance"
  type        = string
  sensitive   = true
}

variable "ssh_priv_key_file" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_domain" {
  description = "Cloudflare domain"
  type        = string
}

variable "environment" {
  description = "Environment for the resources (staging or production)"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Invalid environment name. Allowed values are 'staging' and 'production'."
  }
}

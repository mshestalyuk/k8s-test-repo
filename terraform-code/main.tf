# Tell Terraform to include the hcloud provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      # Here we use version 1.56.0, this may change in the future
      version = "1.56.0"
    }
  }
}

data "hcloud_ssh_key" "by_name" {
  name="mshestalyuk@MaksPC"
}

# Declare the hcloud_token variable from .tfvars
variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}

# Configure the Hetzner Cloud Provider with your token
provider "hcloud" {
  token = var.hcloud_token
}

# VPC
resource "hcloud_network" "private_network" {
  name     = "k8s-cluster-lab-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

output "network_id" {
  value = hcloud_network.private_network.id
}


resource "hcloud_server" "master-node" {
  name        = "master-node"
  image       = "ubuntu-24.04"
  server_type = "cax11"
  location    = "fsn1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
    # IP Used by the master node, needs to be static
    # Here the worker nodes will use 10.0.1.1 to communicate with the master node
    ip         = "10.0.1.1"
  }
  user_data = file("${path.module}/cloud-init.yaml")
  ssh_keys = [
    data.hcloud_ssh_key.by_name.id
  ]
  depends_on = [hcloud_network_subnet.private_network_subnet]
}

resource "hcloud_server" "worker-nodes" {
  count = 2
  
  name        = "worker-node-${count.index}"
  image       = "ubuntu-24.04"
  server_type = "cax11"
  location    = "fsn1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
  }
  user_data = file("${path.module}/cloud-init-worker.yaml")
  ssh_keys = [
    data.hcloud_ssh_key.by_name.id
  ]
  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master-node]
}

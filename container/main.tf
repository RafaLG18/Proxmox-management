terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.77"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = false
    username = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key)
    node {
      name    = var.proxmox_node
      address = var.proxmox_host
      port    = var.proxmox_ssh_port
    }
  }
}

resource "proxmox_download_file" "ubuntu_lxc_template" {
  content_type = "vztmpl"
  datastore_id = var.iso_datastore
  node_name    = var.proxmox_node

  url       = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  file_name = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "container" {
  depends_on = [proxmox_download_file.ubuntu_lxc_template]

  node_name = var.proxmox_node
  vm_id     = var.container_id

  description = "Ubuntu 24.04 LTS container - criado por Terraform"
  tags        = var.container_tags

  started    = true
  unprivileged = var.unprivileged

  initialization {
    hostname = var.container_hostname

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.container_ip
        gateway = var.container_gateway
      }
    }

    user_account {
      keys     = var.ssh_keys
      password = var.root_password
    }
  }

  network_interface {
    name     = "eth0"
    bridge   = var.network_bridge
    firewall = false
  }

  operating_system {
    template_file_id = proxmox_download_file.ubuntu_lxc_template.id
    type             = "ubuntu"
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size_gb
  }

  features {
    nesting = var.feature_nesting
  }
}

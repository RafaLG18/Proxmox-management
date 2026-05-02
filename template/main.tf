terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.104"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent       = false
    username    = var.proxmox_ssh_user
    private_key = file(var.proxmox_ssh_private_key)
    node {
      name    = var.proxmox_node
      address = var.proxmox_host
      port    = var.proxmox_ssh_port
    }
  }
}

resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.proxmox_node

  url       = var.cloud_image_url
  file_name = var.cloud_image_filename

  overwrite            = false
  overwrite_unmanaged  = true
}

resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  depends_on = [proxmox_download_file.ubuntu_cloud_image]

  name      = var.template_name
  node_name = var.proxmox_node
  vm_id     = var.template_vmid
  template  = true

  description = "Ubuntu 24.04 LTS (Noble Numbat) cloud image template - created by Terraform"
  tags        = ["ubuntu", "24.04", "template", "cloud-init"]

  cpu {
    cores   = var.cpu_cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.disk_datastore
    file_id      = proxmox_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    size         = var.disk_size_gb
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    trim    = true
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = var.disk_datastore

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.cloud_init_user
      keys     = var.cloud_init_ssh_keys
      password = var.cloud_init_password
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys,
    ]
  }
}

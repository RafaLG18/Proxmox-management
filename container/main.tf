terraform {
  required_version = ">= 1.3"

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

  url       = "https://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  file_name = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  checksum_algorithm = "sha512"
  checksum           = "45c2978e6b97fe292ada95fe06834276015e5739a594db4de2fdfd830fa0c37942e8ae118fc1e32ffd9154b3f9378b592738b668ea3957db41f2907b86f219de"

  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "container" {
  node_name = var.proxmox_node
  vm_id     = var.container_id

  description = "Ubuntu 24.04 LTS container - criado por Terraform"
  tags        = var.container_tags

  started    = true
  unprivileged = true

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
      keys = var.ssh_keys
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
    keyctl  = false
    fuse    = false
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = split("/", var.container_ip)[0]
    private_key = file(var.proxmox_ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = concat(
      [
        "useradd -m -s /bin/bash ${var.container_user}",
        "mkdir -p /home/${var.container_user}/.ssh",
        "chmod 700 /home/${var.container_user}/.ssh",
        "touch /home/${var.container_user}/.ssh/authorized_keys",
      ],
      [for key in var.user_ssh_keys : "echo '${key}' >> /home/${var.container_user}/.ssh/authorized_keys"],
      [
        "chmod 600 /home/${var.container_user}/.ssh/authorized_keys",
        "chown -R ${var.container_user}:${var.container_user} /home/${var.container_user}/.ssh",
        "usermod -aG sudo ${var.container_user}",
        "echo '${var.container_user} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${var.container_user}",
        "chmod 440 /etc/sudoers.d/${var.container_user}",
        "printf 'PasswordAuthentication no\\nPermitRootLogin prohibit-password\\nMaxAuthTries 3\\n' > /etc/ssh/sshd_config.d/99-hardening.conf",
        "chmod 600 /etc/ssh/sshd_config.d/99-hardening.conf",
        "systemctl restart ssh",
      ]
    )
  }
}

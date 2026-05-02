variable "proxmox_endpoint" {
  description = "URL do endpoint da API do Proxmox (ex: https://192.168.1.10:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "API Token do Proxmox no formato 'USER@REALM!TOKENID=SECRET' (ex: terraform@pve!mytoken=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Ignorar verificação de certificado TLS (true para self-signed)"
  type        = bool
  default     = false
}

variable "proxmox_host" {
  description = "IP ou hostname do nó Proxmox para conexão SSH"
  type        = string
}

variable "proxmox_ssh_user" {
  description = "Usuário SSH do nó Proxmox"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_port" {
  description = "Porta SSH do nó Proxmox"
  type        = number
  default     = 22
}

variable "proxmox_ssh_private_key" {
  description = "Caminho para a chave privada SSH usada para conectar ao Proxmox"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "proxmox_node" {
  description = "Nome do nó do Proxmox onde o template será criado"
  type        = string
}

variable "template_name" {
  description = "Nome do template de VM"
  type        = string
  default     = "ubuntu-24.04-template"
}

variable "template_vmid" {
  description = "ID da VM do template (recomendado: 9000+)"
  type        = number
  default     = 9000

  validation {
    condition     = var.template_vmid >= 100 && var.template_vmid <= 999999999
    error_message = "O VM ID deve estar entre 100 e 999999999."
  }
}

variable "iso_datastore" {
  description = "Datastore onde a imagem ISO/cloud será armazenada"
  type        = string
  default     = "local"
}

variable "disk_datastore" {
  description = "Datastore onde o disco da VM será armazenado"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge de rede do Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "cpu_cores" {
  description = "Número de cores de CPU do template"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 1 && var.cpu_cores <= 128
    error_message = "O número de cores deve estar entre 1 e 128."
  }
}

variable "memory_mb" {
  description = "Memória RAM em MB"
  type        = number
  default     = 2048

  validation {
    condition     = var.memory_mb >= 512
    error_message = "A memória deve ser de no mínimo 512 MB."
  }
}

variable "disk_size_gb" {
  description = "Tamanho do disco em GB"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 8
    error_message = "O disco deve ter no mínimo 8 GB."
  }
}

variable "cloud_init_user" {
  description = "Usuário padrão criado pelo cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_ssh_keys" {
  description = "Lista de chaves SSH públicas para o usuário cloud-init"
  type        = list(string)
  default     = []
}

variable "cloud_init_password" {
  description = "Senha do usuário cloud-init (opcional — recomendado apenas para acesso via console)"
  type        = string
  sensitive   = true
  default     = null
}

variable "cloud_image_url" {
  description = "URL da imagem cloud a ser baixada para o Proxmox"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "cloud_image_filename" {
  description = "Nome do arquivo da imagem cloud no datastore do Proxmox"
  type        = string
  default     = "noble-server-cloudimg-amd64.img"
}

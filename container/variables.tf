# --- Provider ---

variable "proxmox_endpoint" {
  description = "URL do endpoint da API do Proxmox (ex: https://192.168.1.10:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "API Token do Proxmox no formato 'USER@REALM!TOKENID=SECRET'"
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
  description = "Nome do nó do Proxmox onde o container será criado"
  type        = string
}

# --- Datastores / Rede ---

variable "iso_datastore" {
  description = "Datastore onde o template LXC será armazenado"
  type        = string
  default     = "local"
}

variable "disk_datastore" {
  description = "Datastore onde o disco do container será armazenado"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge de rede do Proxmox"
  type        = string
  default     = "vmbr0"
}

# --- Container ---

variable "container_id" {
  description = "ID do container LXC. Se não informado, usa o próximo VMID disponível no Proxmox"
  type        = number
  default     = null
  nullable    = true
}

variable "container_hostname" {
  description = "Hostname do container"
  type        = string
  default     = "ubuntu-container"
}

variable "container_tags" {
  description = "Tags do container"
  type        = list(string)
  default     = ["ubuntu", "24.04", "terraform"]
}

variable "feature_nesting" {
  description = "Habilitar nesting (necessário para Docker dentro do container)"
  type        = bool
  default     = false
}

# --- Rede do Container ---

variable "container_ip" {
  description = "IP do container com máscara CIDR (ex: 192.168.1.100/24) — DHCP não é suportado"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.container_ip))
    error_message = "O IP deve estar no formato CIDR (ex: 192.168.1.100/24). DHCP não é suportado."
  }
}

variable "container_gateway" {
  description = "Gateway padrão do container (ex: 192.168.1.1)"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.container_gateway))
    error_message = "O gateway deve ser um endereço IPv4 válido (ex: 192.168.1.1)."
  }
}

variable "dns_servers" {
  description = "Lista de servidores DNS do container"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "dns_domain" {
  description = "Domínio de busca DNS do container"
  type        = string
  default     = null
}

# --- Recursos ---

variable "cpu_cores" {
  description = "Número de cores de CPU"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memória RAM em MB"
  type        = number
  default     = 512
}

variable "swap_mb" {
  description = "Memória swap em MB"
  type        = number
  default     = 512
}

variable "disk_size_gb" {
  description = "Tamanho do disco raiz em GB"
  type        = number
  default     = 8
}

# --- Acesso ---

variable "ssh_keys" {
  description = "Chaves SSH públicas do root (deve conter a chave pública correspondente a proxmox_ssh_private_key para o remote-exec funcionar)"
  type        = list(string)

  validation {
    condition     = length(var.ssh_keys) > 0
    error_message = "Pelo menos uma chave SSH deve ser fornecida para o root."
  }
}

variable "container_user" {
  description = "Nome do usuário não-root a ser criado no container"
  type        = string

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.container_user))
    error_message = "Nome de usuário inválido. Use apenas letras minúsculas, números, hífen ou underscore (máx. 32 caracteres)."
  }
}

variable "user_ssh_keys" {
  description = "Chaves SSH públicas autorizadas para o container_user"
  type        = list(string)

  validation {
    condition     = length(var.user_ssh_keys) > 0
    error_message = "Pelo menos uma chave SSH deve ser fornecida para o usuário do container."
  }
}


# Proxmox Management

Módulos Terraform para gerenciamento de recursos no Proxmox VE.

## Módulos

| Módulo | Descrição |
|---|---|
| [`template/`](template/) | Cria um template de VM Ubuntu 24.04 LTS com cloud-init |
| [`container/`](container/) | Cria um container LXC Ubuntu 24.04 LTS |

## Permissões

Antes de usar qualquer módulo, configure o token de API do Proxmox conforme descrito em [PERMISSIONS.md](PERMISSIONS.md).

## Pré-requisitos

- Terraform >= 1.3
- Proxmox VE >= 8.0
- Chave SSH configurada para acesso ao nó Proxmox

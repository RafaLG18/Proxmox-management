# Proxmox Ubuntu 24.04 Template

Código Terraform para criar um template de VM Ubuntu 24.04 LTS (Noble Numbat) no Proxmox VE, usando cloud image oficial e cloud-init.

## O que este código faz

1. Baixa a cloud image oficial do Ubuntu 24.04 diretamente no Proxmox via API
2. Cria uma VM configurada com cloud-init, qemu-guest-agent e virtio
3. Converte a VM em template (`template = true`), pronta para ser clonada

## Estrutura

```
.
├── main.tf                   # Provider, download da imagem e criação do template
├── variables.tf              # Declaração de todas as variáveis
├── outputs.tf                # Valores exportados após o apply
├── deploy.sh                 # Script de deploy (init/plan/apply/destroy/output)
├── .env.example              # Exemplo de variáveis de ambiente — copie para .env
├── terraform.tfvars.example  # Alternativa ao .env para configuração via tfvars
└── .gitignore                # Exclui .env, terraform.tfvars e state do git
```

## Pré-requisitos

- Terraform >= 1.5
- Proxmox VE >= 8.0
- API Token com as permissões corretas (veja [PERMISSIONS.md](../PERMISSIONS.md))
- Chave SSH configurada para acesso ao nó Proxmox
- Acesso à internet a partir do nó Proxmox para baixar a cloud image

> **Atenção:** O provider usa Go para conexões SSH e não suporta chaves DSA. Se houver entradas DSA no `~/.ssh/known_hosts`, remova-as antes de rodar o Terraform:
> ```bash
> sed -i '/ssh-dss/d' ~/.ssh/known_hosts
> ```

## Tutorial de deploy

### 1. Configure as variáveis de ambiente

Copie o arquivo de exemplo e preencha com seus valores:

```bash
cp .env.example .env
```

Edite o `.env` com as configurações do seu ambiente. Os campos obrigatórios são:

```bash
TF_VAR_proxmox_endpoint="https://192.168.1.10:8006/"
TF_VAR_proxmox_api_token="terraform@pve!mytoken=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
TF_VAR_proxmox_host="192.168.1.10"
TF_VAR_proxmox_node="pve"
```

### 2. Configure o acesso via cloud-init

Defina o usuário e chave SSH que serão criados no template:

```bash
TF_VAR_cloud_init_user="ubuntu"
TF_VAR_cloud_init_ssh_keys='["ssh-ed25519 AAAAC3... seu-comentario"]'
# TF_VAR_cloud_init_password="sua-senha"  # opcional — apenas para acesso via console
```

### 3. Inicialize o Terraform

```bash
./deploy.sh init
```

### 4. Revise o plano

```bash
./deploy.sh plan
```

Verifique os recursos que serão criados antes de aplicar.

### 5. Aplique

```bash
./deploy.sh apply
```

O script exibirá o plano de execução e pedirá confirmação antes de aplicar. Ao final, os outputs mostrarão o ID e nome do template criado.

### 6. Clone o template

Após o apply, o template estará disponível no painel do Proxmox para ser clonado. Via Terraform em outro módulo:

```hcl
resource "proxmox_virtual_environment_vm" "minha_vm" {
  name      = "minha-vm"
  node_name = "pve"

  clone {
    vm_id = 9000  # ID do template criado
    full  = true
  }
}
```

## Variáveis

### Provider

| Variável | Descrição | Padrão |
|---|---|---|
| `proxmox_endpoint` | URL da API do Proxmox (ex: `https://192.168.1.10:8006/`) | — |
| `proxmox_api_token` | API Token no formato `USER@REALM!TOKENID=SECRET` | — |
| `proxmox_insecure` | Ignorar verificação TLS (para certificados self-signed) | `false` |
| `proxmox_node` | Nome do nó Proxmox onde o template será criado | — |
| `proxmox_host` | IP ou hostname do nó para conexão SSH | — |
| `proxmox_ssh_user` | Usuário SSH do nó | `root` |
| `proxmox_ssh_port` | Porta SSH do nó | `22` |
| `proxmox_ssh_private_key` | Caminho para a chave privada SSH | `~/.ssh/id_ed25519` |

### Infraestrutura

| Variável | Descrição | Padrão |
|---|---|---|
| `iso_datastore` | Datastore para armazenar a cloud image | `local` |
| `disk_datastore` | Datastore para o disco da VM | `local-lvm` |
| `network_bridge` | Bridge de rede do Proxmox | `vmbr0` |

### Template

| Variável | Descrição | Padrão |
|---|---|---|
| `template_name` | Nome do template | `ubuntu-24.04-template` |
| `template_vmid` | ID da VM do template | `9000` |

### Recursos

| Variável | Descrição | Padrão |
|---|---|---|
| `cpu_cores` | Número de cores de CPU | `2` |
| `memory_mb` | Memória RAM em MB | `2048` |
| `disk_size_gb` | Tamanho do disco em GB | `20` |

### Cloud image

| Variável | Descrição | Padrão |
|---|---|---|
| `cloud_image_url` | URL da imagem cloud a ser baixada para o Proxmox | URL oficial Ubuntu 24.04 |
| `cloud_image_filename` | Nome do arquivo da imagem no datastore | `noble-server-cloudimg-amd64.img` |

### Cloud-init

| Variável | Descrição | Padrão |
|---|---|---|
| `cloud_init_user` | Usuário padrão criado pelo cloud-init | `ubuntu` |
| `cloud_init_ssh_keys` | Lista de chaves SSH públicas para o usuário | `[]` |
| `cloud_init_password` | Senha do usuário (opcional — para acesso via console) | `null` |

## Outputs

| Output | Descrição |
|---|---|
| `template_vm_id` | ID da VM do template criado |
| `template_name` | Nome do template criado |
| `cloud_image_id` | ID do arquivo de imagem cloud baixado |

## Detalhes técnicos

- **Imagem**: Ubuntu 24.04 LTS cloud image oficial (`noble-server-cloudimg-amd64.img`)
- **CPU**: tipo `host` (passa as instruções do CPU físico para a VM)
- **Disco**: interface `virtio0` com discard e iothread habilitados
- **Rede**: modelo `virtio` na bridge configurada
- **VGA**: serial0 (otimizado para uso headless/cloud)
- **QEMU Guest Agent**: habilitado com trim de disco
- **Cloud-init**: IP via DHCP, usuário e chaves SSH configuráveis

## Remover o template

```bash
./deploy.sh destroy
```

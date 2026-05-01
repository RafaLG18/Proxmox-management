# Proxmox Ubuntu 24.04 Container

Código Terraform para criar um container LXC Ubuntu 24.04 LTS no Proxmox VE.

## O que este código faz

1. Baixa o template LXC oficial do Ubuntu 24.04 diretamente no Proxmox via API
2. Cria um container LXC configurado com rede, DNS e acesso SSH
3. Inicia o container automaticamente

## Estrutura

```
.
├── main.tf                   # Provider, download do template e criação do container
├── variables.tf              # Declaração de todas as variáveis
├── outputs.tf                # Valores exportados após o apply
├── deploy.sh                 # Script de deploy (init/plan/apply/destroy/output)
├── .env.example              # Exemplo de variáveis de ambiente — copie para .env
├── terraform.tfvars.example  # Alternativa ao .env para configuração via tfvars
└── .gitignore                # Exclui .env, terraform.tfvars e state do git
```

## Pré-requisitos

- Terraform >= 1.3
- Proxmox VE >= 8.0
- API Token com as permissões corretas (veja [PERMISSIONS.md](../PERMISSIONS.md))
- Chave SSH configurada para acesso ao nó Proxmox
- Acesso à internet a partir do nó Proxmox para baixar o template LXC

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

### 2. Configure o acesso ao container

Defina senha e/ou chave SSH para o root:

```bash
TF_VAR_root_password="sua-senha"
TF_VAR_ssh_keys='["ssh-ed25519 AAAAC3... seu-comentario"]'
```

### 3. Configure a rede

**DHCP (padrão):**
```bash
TF_VAR_container_ip="dhcp"
```

**IP fixo:**
```bash
TF_VAR_container_ip="192.168.1.100/24"
TF_VAR_container_gateway="192.168.1.1"
```

### 4. Inicialize o Terraform

```bash
./deploy.sh init
```

### 5. Revise o plano

```bash
./deploy.sh plan
```

Verifique os recursos que serão criados antes de aplicar.

### 6. Aplique

```bash
./deploy.sh apply
```

Ao final, os outputs mostrarão o ID e IP do container criado.

### 7. Acesse o container

Via SSH:
```bash
ssh root@<ip-do-container>
```

Via console no Proxmox (sem precisar de rede):
```bash
pct enter <id-do-container>
```

## Variáveis

### Provider

| Variável | Descrição | Padrão |
|---|---|---|
| `proxmox_endpoint` | URL da API do Proxmox (ex: `https://192.168.1.10:8006/`) | — |
| `proxmox_api_token` | API Token no formato `USER@REALM!TOKENID=SECRET` | — |
| `proxmox_insecure` | Ignorar verificação TLS (para certificados self-signed) | `false` |
| `proxmox_node` | Nome do nó Proxmox | — |
| `proxmox_host` | IP ou hostname do nó para conexão SSH | — |
| `proxmox_ssh_user` | Usuário SSH do nó | `root` |
| `proxmox_ssh_port` | Porta SSH do nó | `22` |
| `proxmox_ssh_private_key` | Caminho para a chave privada SSH | `~/.ssh/id_ed25519` |

### Infraestrutura

| Variável | Descrição | Padrão |
|---|---|---|
| `iso_datastore` | Datastore para armazenar o template LXC | `local` |
| `disk_datastore` | Datastore para o disco do container | `local-lvm` |
| `network_bridge` | Bridge de rede do Proxmox | `vmbr0` |

### Container

| Variável | Descrição | Padrão |
|---|---|---|
| `container_id` | ID do container LXC | `100` |
| `container_hostname` | Hostname do container | `ubuntu-container` |
| `container_tags` | Tags do container | `["ubuntu", "24.04", "terraform"]` |
| `unprivileged` | Criar container sem privilégios (recomendado) | `true` |
| `feature_nesting` | Habilitar nesting (necessário para rodar Docker) | `false` |

### Rede

| Variável | Descrição | Padrão |
|---|---|---|
| `container_ip` | IP com máscara CIDR ou `dhcp` | `dhcp` |
| `container_gateway` | Gateway padrão (deixe `null` se usar DHCP) | `null` |
| `dns_servers` | Lista de servidores DNS | `["1.1.1.1", "8.8.8.8"]` |
| `dns_domain` | Domínio de busca DNS | `null` |

### Recursos

| Variável | Descrição | Padrão |
|---|---|---|
| `cpu_cores` | Número de cores de CPU | `1` |
| `memory_mb` | Memória RAM em MB | `512` |
| `swap_mb` | Memória swap em MB | `512` |
| `disk_size_gb` | Tamanho do disco raiz em GB | `8` |

### Acesso

| Variável | Descrição | Padrão |
|---|---|---|
| `ssh_keys` | Chaves SSH públicas para o root | `[]` |
| `root_password` | Senha do root | `null` |

## Outputs

| Output | Descrição |
|---|---|
| `container_id` | ID do container criado |
| `container_hostname` | Hostname do container |
| `container_ip` | Configuração de IP do container |
| `lxc_template_id` | ID do template LXC baixado no datastore |

## Remover o container

```bash
./deploy.sh destroy
```

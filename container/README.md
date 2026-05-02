# Proxmox Ubuntu 24.04 Container

Código Terraform para criar um container LXC Ubuntu 24.04 LTS no Proxmox VE com boas práticas de segurança aplicadas.

## O que este código faz

1. Baixa o template LXC oficial do Ubuntu 24.04 diretamente no Proxmox via API (com verificação de checksum SHA-512)
2. Cria um container LXC não-privilegiado com rede, DNS e acesso SSH
3. Inicia o container automaticamente
4. Via `remote-exec`, cria um usuário não-root com chave SSH e permissões sudo

## Segurança aplicada

- Container sempre não-privilegiado (`unprivileged = true` fixo)
- Acesso root apenas via chave SSH (sem senha)
- Usuário não-root criado automaticamente com sudo sem senha
- Features `keyctl` e `fuse` explicitamente desabilitadas
- Checksum SHA-512 verificado no download do template
- IP fixo obrigatório (necessário para o `remote-exec` funcionar)

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

Os campos obrigatórios são:

```bash
TF_VAR_proxmox_endpoint="https://192.168.1.10:8006/"
TF_VAR_proxmox_api_token="terraform@pve!mytoken=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
TF_VAR_proxmox_host="192.168.1.10"
TF_VAR_proxmox_node="pve"
```

### 2. Configure o acesso SSH

O acesso ao container é feito exclusivamente via chave SSH. O valor de `ssh_keys` deve conter **apenas a parte base64 da chave**, sem o prefixo de tipo — o Proxmox adiciona o tipo automaticamente:

```bash
# Correto — apenas a parte base64:
TF_VAR_ssh_keys='["AAAAC3NzaC1lZDI1NTE5AAAAIOc4k2e5KgOFohimVuoogMFcHH0zqfP3LQHd8JKwU6tP"]'

# Errado — com prefixo de tipo (vai duplicar o tipo no authorized_keys):
TF_VAR_ssh_keys='["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc4k2e5KgOFohimVuoogMFcHH0zqfP3LQHd8JKwU6tP"]'
```

A chave pública correspondente a `proxmox_ssh_private_key` deve estar em `ssh_keys` — é ela que permite o `remote-exec` conectar como root no container após a criação.

### 3. Configure o usuário não-root

Defina o nome do usuário e as chaves SSH que terão acesso a ele. O `user_ssh_keys` aceita o formato completo (`ssh-ed25519 AAAAC3...`):

```bash
TF_VAR_container_user="rafael"
TF_VAR_user_ssh_keys='["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc4k2e5KgOFohimVuoogMFcHH0zqfP3LQHd8JKwU6tP"]'
```

### 4. Configure a rede

IP fixo é obrigatório — DHCP não é suportado pois o `remote-exec` precisa de um endereço conhecido para conectar:

```bash
TF_VAR_container_ip="192.168.1.100/24"
TF_VAR_container_gateway="192.168.1.1"
```

### 5. Inicialize o Terraform

```bash
./deploy.sh init
```

### 6. Revise o plano

```bash
./deploy.sh plan
```

Verifique os recursos que serão criados antes de aplicar.

### 7. Aplique

```bash
./deploy.sh apply
```

Ao final, os outputs mostrarão o ID e IP do container criado.

### 8. Acesse o container

Via SSH com o usuário não-root:
```bash
ssh rafael@<ip-do-container>
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
| `proxmox_ssh_private_key` | Caminho para a chave privada SSH do nó Proxmox | `~/.ssh/id_ed25519` |

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
| `feature_nesting` | Habilitar nesting (necessário para rodar Docker) | `false` |

### Rede

| Variável | Descrição | Padrão |
|---|---|---|
| `container_ip` | IP com máscara CIDR — DHCP não suportado | — |
| `container_gateway` | Gateway padrão | — |
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
| `ssh_keys` | Chaves SSH do root — somente a parte base64, sem prefixo de tipo | — |
| `container_user` | Nome do usuário não-root criado via `remote-exec` | — |
| `user_ssh_keys` | Chaves SSH públicas para o `container_user` (formato completo) | — |

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

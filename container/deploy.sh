#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$(dirname "$0")/.env"

# --- Funções auxiliares ---
log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

usage() {
  cat <<EOF
Uso: $0 <comando>

Comandos:
  init      Inicializa o Terraform (terraform init)
  plan      Exibe o plano de execução
  apply     Cria o container no Proxmox
  destroy   Remove o container e o template LXC do Proxmox
  output    Exibe os outputs do state atual

EOF
  exit 1
}

# --- Validações ---
[[ $# -lt 1 ]] && usage

command -v terraform &>/dev/null || die "Terraform não encontrado. Instale em: https://developer.hashicorp.com/terraform/install"

if [[ ! -f "$ENV_FILE" ]]; then
  die "Arquivo .env não encontrado. Copie o exemplo e preencha:\n  cp .env.example .env"
fi

# Carrega as variáveis de ambiente
set -a
# shellcheck source=.env
source "$ENV_FILE"
set +a

log "Ambiente carregado de: $ENV_FILE"

# --- Comandos ---
CMD="$1"

case "$CMD" in
  init)
    log "Inicializando Terraform..."
    terraform init
    ;;

  plan)
    log "Gerando plano de execução..."
    terraform plan
    ;;

  apply)
    log "Aplicando configuração..."
    terraform apply -auto-approve
    log "Deploy concluído."
    terraform output
    ;;

  destroy)
    warn "Isso irá remover o container e o template LXC do Proxmox."
    read -rp "Tem certeza? Digite 'yes' para confirmar: " confirm
    [[ "$confirm" == "yes" ]] || die "Operação cancelada."
    terraform destroy -auto-approve
    log "Recursos removidos."
    ;;

  output)
    terraform output
    ;;

  *)
    die "Comando desconhecido: '$CMD'"
    ;;
esac

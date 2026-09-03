#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"

log() {
  echo "[remote] $*"
}

die() {
  echo "[remote] Erro: $*" >&2
  exit 1
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    die "variável obrigatória ausente: $name"
  fi
}

shell_quote() {
  printf "%q" "$1"
}

load_env_file() {
  local env_file="$repo_dir/.env"
  if [[ -f "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

validate_local_env() {
  require_env SERVER_HOST
  require_env SERVER_USER
  require_env SSH_KEY_PATH

  [[ -r "$SSH_KEY_PATH" ]] || die "SSH_KEY_PATH não aponta para um arquivo legível: $SSH_KEY_PATH"

  SSH_PORT="${SSH_PORT:-22}"
  [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || die "SSH_PORT deve ser numérica"

  BOOTSTRAP_TIMEZONE="${BOOTSTRAP_TIMEZONE:-}"
  ENABLE_UFW="${ENABLE_UFW:-true}"
  COOLIFY_INSTALL_URL="${COOLIFY_INSTALL_URL:-https://cdn.coollabs.io/coolify/install.sh}"
  COOLIFY_EXPECTED_DIR="${COOLIFY_EXPECTED_DIR:-/data/coolify/source}"
  FOUNDRY_INSTALL_URL="${FOUNDRY_INSTALL_URL:-https://signoz.io/foundry.sh}"
  FOUNDRY_VERSION="${FOUNDRY_VERSION:-}"
  FOUNDRY_BIN_PATH="${FOUNDRY_BIN_PATH:-/usr/local/bin/foundryctl}"
  SIGNOZ_DIR="${SIGNOZ_DIR:-/data/signoz}"
  SIGNOZ_UI_PORT="${SIGNOZ_UI_PORT:-8081}"
  [[ "$SIGNOZ_UI_PORT" =~ ^[0-9]+$ ]] || die "SIGNOZ_UI_PORT deve ser numérica"
  ENABLE_SIGNOZ_FIREWALL="${ENABLE_SIGNOZ_FIREWALL:-true}"
  POSTGRES_COLLECTOR_ENABLED="${POSTGRES_COLLECTOR_ENABLED:-true}"
  POSTGRES_COLLECTOR_DIR="${POSTGRES_COLLECTOR_DIR:-/data/signoz-integrations/postgres-collector}"
  POSTGRES_COLLECTOR_IMAGE="${POSTGRES_COLLECTOR_IMAGE:-otel/opentelemetry-collector-contrib:0.139.0}"
  POSTGRES_COLLECTOR_CONTAINER="${POSTGRES_COLLECTOR_CONTAINER:-espresso-postgres-collector}"
  POSTGRES_COLLECTOR_COOLIFY_NETWORK="${POSTGRES_COLLECTOR_COOLIFY_NETWORK:-coolify}"
  POSTGRES_COLLECTOR_SIGNOZ_NETWORK="${POSTGRES_COLLECTOR_SIGNOZ_NETWORK:-signoz-network}"
  POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT="${POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT:-signoz-ingester:4317}"
  POSTGRES_COLLECTOR_COOLIFY_PROJECT="${POSTGRES_COLLECTOR_COOLIFY_PROJECT:-espresso}"
  POSTGRES_COLLECTOR_POSTGRES_CONTAINER="${POSTGRES_COLLECTOR_POSTGRES_CONTAINER:-}"
  POSTGRES_COLLECTOR_POSTGRES_HOST="${POSTGRES_COLLECTOR_POSTGRES_HOST:-}"
  POSTGRES_COLLECTOR_POSTGRES_PORT="${POSTGRES_COLLECTOR_POSTGRES_PORT:-5432}"
  [[ "$POSTGRES_COLLECTOR_POSTGRES_PORT" =~ ^[0-9]+$ ]] || die "POSTGRES_COLLECTOR_POSTGRES_PORT deve ser numérica"
  POSTGRES_COLLECTOR_POSTGRES_DB="${POSTGRES_COLLECTOR_POSTGRES_DB:-}"
  POSTGRES_MONITOR_USER="${POSTGRES_MONITOR_USER:-espresso_otel_monitor}"
  POSTGRES_COLLECTOR_INTERVAL="${POSTGRES_COLLECTOR_INTERVAL:-30s}"
  POSTGRES_COLLECTOR_ENVIRONMENT="${POSTGRES_COLLECTOR_ENVIRONMENT:-production}"
}

ssh_target() {
  printf "%s@%s" "$SERVER_USER" "$SERVER_HOST"
}

ssh_base_args() {
  printf "%s\n" \
    -i "$SSH_KEY_PATH" \
    -p "$SSH_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3
}

remote_env_prefix() {
  printf "BOOTSTRAP_TIMEZONE=%s " "$(shell_quote "$BOOTSTRAP_TIMEZONE")"
  printf "BOOTSTRAP_SSH_PORT=%s " "$(shell_quote "$SSH_PORT")"
  printf "BOOTSTRAP_SSH_USER=%s " "$(shell_quote "$SERVER_USER")"
  printf "ENABLE_UFW=%s " "$(shell_quote "$ENABLE_UFW")"
  printf "COOLIFY_INSTALL_URL=%s " "$(shell_quote "$COOLIFY_INSTALL_URL")"
  printf "COOLIFY_EXPECTED_DIR=%s " "$(shell_quote "$COOLIFY_EXPECTED_DIR")"
  printf "FOUNDRY_INSTALL_URL=%s " "$(shell_quote "$FOUNDRY_INSTALL_URL")"
  printf "FOUNDRY_VERSION=%s " "$(shell_quote "$FOUNDRY_VERSION")"
  printf "FOUNDRY_BIN_PATH=%s " "$(shell_quote "$FOUNDRY_BIN_PATH")"
  printf "SIGNOZ_DIR=%s " "$(shell_quote "$SIGNOZ_DIR")"
  printf "SIGNOZ_UI_PORT=%s " "$(shell_quote "$SIGNOZ_UI_PORT")"
  printf "ENABLE_SIGNOZ_FIREWALL=%s " "$(shell_quote "$ENABLE_SIGNOZ_FIREWALL")"
  printf "POSTGRES_COLLECTOR_ENABLED=%s " "$(shell_quote "$POSTGRES_COLLECTOR_ENABLED")"
  printf "POSTGRES_COLLECTOR_DIR=%s " "$(shell_quote "$POSTGRES_COLLECTOR_DIR")"
  printf "POSTGRES_COLLECTOR_IMAGE=%s " "$(shell_quote "$POSTGRES_COLLECTOR_IMAGE")"
  printf "POSTGRES_COLLECTOR_CONTAINER=%s " "$(shell_quote "$POSTGRES_COLLECTOR_CONTAINER")"
  printf "POSTGRES_COLLECTOR_COOLIFY_NETWORK=%s " "$(shell_quote "$POSTGRES_COLLECTOR_COOLIFY_NETWORK")"
  printf "POSTGRES_COLLECTOR_SIGNOZ_NETWORK=%s " "$(shell_quote "$POSTGRES_COLLECTOR_SIGNOZ_NETWORK")"
  printf "POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT=%s " "$(shell_quote "$POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT")"
  printf "POSTGRES_COLLECTOR_COOLIFY_PROJECT=%s " "$(shell_quote "$POSTGRES_COLLECTOR_COOLIFY_PROJECT")"
  printf "POSTGRES_COLLECTOR_POSTGRES_CONTAINER=%s " "$(shell_quote "$POSTGRES_COLLECTOR_POSTGRES_CONTAINER")"
  printf "POSTGRES_COLLECTOR_POSTGRES_HOST=%s " "$(shell_quote "$POSTGRES_COLLECTOR_POSTGRES_HOST")"
  printf "POSTGRES_COLLECTOR_POSTGRES_PORT=%s " "$(shell_quote "$POSTGRES_COLLECTOR_POSTGRES_PORT")"
  printf "POSTGRES_COLLECTOR_POSTGRES_DB=%s " "$(shell_quote "$POSTGRES_COLLECTOR_POSTGRES_DB")"
  printf "POSTGRES_MONITOR_USER=%s " "$(shell_quote "$POSTGRES_MONITOR_USER")"
  printf "POSTGRES_COLLECTOR_INTERVAL=%s " "$(shell_quote "$POSTGRES_COLLECTOR_INTERVAL")"
  printf "POSTGRES_COLLECTOR_ENVIRONMENT=%s " "$(shell_quote "$POSTGRES_COLLECTOR_ENVIRONMENT")"
}

run_ssh_command() {
  local remote_command="$1"
  mapfile -t args < <(ssh_base_args)
  ssh "${args[@]}" "$(ssh_target)" "$remote_command"
}

run_remote_script() {
  local script_name="$1"
  local script_path="$script_dir/$script_name.sh"
  local common_path="$script_dir/server-lib.sh"
  local combined_script

  [[ -f "$script_path" ]] || die "script não encontrado: $script_path"
  [[ -f "$common_path" ]] || die "biblioteca remota não encontrada: $common_path"

  combined_script="$(mktemp "${TMPDIR:-/tmp}/espresso-bootstrap.XXXXXX")"
  trap 'rm -f -- "${combined_script:-}"' RETURN

  sed '1{/^#!/d;}' "$common_path" > "$combined_script"
  sed '1{/^#!/d;}' "$script_path" >> "$combined_script"

  mapfile -t args < <(ssh_base_args)
  log "executando scripts/$script_name.sh em $(ssh_target)"
  ssh "${args[@]}" "$(ssh_target)" "$(remote_env_prefix) bash -s" < "$combined_script"
}

main() {
  local action="${1:-}"
  shift || true

  load_env_file
  validate_local_env

  case "$action" in
    preflight)
      log "validando conectividade SSH com $(ssh_target)"
      run_ssh_command "true"
      log "preflight concluído"
      ;;
    command)
      [[ "$#" -gt 0 ]] || die "informe um comando para executar"
      run_ssh_command "$*"
      ;;
    check-os)
      run_remote_script check-os
      ;;
    system)
      run_remote_script system
      ;;
    security)
      run_remote_script security
      ;;
    docker)
      run_remote_script docker
      ;;
    docker-status)
      run_remote_script docker-status
      ;;
    coolify)
      run_remote_script coolify
      ;;
    coolify-status)
      run_remote_script coolify-status
      ;;
    foundryctl)
      run_remote_script foundryctl
      ;;
    signoz)
      run_remote_script signoz
      ;;
    postgres-collector)
      run_remote_script postgres-collector
      ;;
    signoz-firewall)
      run_remote_script signoz-firewall
      ;;
    observability-status)
      run_remote_script observability-status
      ;;
    status)
      run_remote_script status
      ;;
    *)
      die "ação inválida: ${action:-<vazia>}"
      ;;
  esac
}

main "$@"

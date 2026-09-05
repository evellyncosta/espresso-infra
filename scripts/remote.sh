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
    status)
      run_remote_script status
      ;;
    *)
      die "ação inválida: ${action:-<vazia>}"
      ;;
  esac
}

main "$@"

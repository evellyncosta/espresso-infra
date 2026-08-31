#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family

install_url="${COOLIFY_INSTALL_URL:-https://cdn.coollabs.io/coolify/install.sh}"
coolify_dir="${COOLIFY_EXPECTED_DIR:-/data/coolify/source}"

coolify_containers_found() {
  as_root docker ps --format '{{.Names}}' | grep -E '^coolify|coolify-' >/dev/null 2>&1
}

print_coolify_containers() {
  as_root docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '^coolify|NAMES'
}

command -v curl >/dev/null 2>&1 || die "curl não encontrado; execute a task de sistema antes"
command -v docker >/dev/null 2>&1 || die "docker não encontrado; execute a task install:docker antes"
docker compose version >/dev/null 2>&1 || die "docker compose plugin não encontrado"
service_is_active docker || die "serviço Docker não está ativo"

if path_is_dir_as_root "$coolify_dir" && coolify_containers_found; then
  log "Coolify já instalado; preservando configuração existente"
  print_coolify_containers
  log "Coolify operacional"
  exit 0
fi

for port in 80 443 8000 6001 6002; do
  if port_in_use "$port"; then
    if path_is_dir_as_root "$coolify_dir"; then
      log "porta ${port}/tcp já está em uso; prosseguindo porque pode ser Coolify/proxy existente"
    else
      die "porta ${port}/tcp já está em uso antes da instalação do Coolify"
    fi
  fi
done

if path_is_file_as_root "$coolify_dir/.env"; then
  before_hash="$(as_root sha256sum "$coolify_dir/.env" | awk '{print $1}')"
else
  before_hash=""
fi

log "executando instalador suportado do Coolify"
if [[ "$(id -u)" -eq 0 ]]; then
  curl -fsSL "$install_url" | bash
else
  curl -fsSL "$install_url" | sudo bash
fi

path_is_dir_as_root "$coolify_dir" || die "diretório esperado do Coolify não encontrado: $coolify_dir"

if [[ -n "$before_hash" ]]; then
  after_hash="$(as_root sha256sum "$coolify_dir/.env" | awk '{print $1}')"
  if [[ "$before_hash" != "$after_hash" ]]; then
    die "o arquivo $coolify_dir/.env foi alterado durante reexecução; revise antes de continuar"
  fi
fi

log "verificando containers do Coolify"
if coolify_containers_found; then
  print_coolify_containers
else
  die "containers do Coolify não encontrados após instalação"
fi

log "Coolify instalado e operacional"

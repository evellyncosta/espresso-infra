#!/usr/bin/env bash

set -Eeuo pipefail

log "sistema operacional"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  echo "${PRETTY_NAME:-desconhecido}"
fi

log "docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
  docker compose version || true
  systemctl is-active docker || true
else
  echo "docker não instalado"
fi

log "firewall"
if command -v ufw >/dev/null 2>&1; then
  as_root ufw status || true
else
  echo "ufw não instalado"
fi

log "coolify"
coolify_dir="${COOLIFY_EXPECTED_DIR:-/data/coolify/source}"
if path_is_dir_as_root "$coolify_dir"; then
  echo "diretório encontrado: $coolify_dir"
  if command -v docker >/dev/null 2>&1; then
    as_root docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '^coolify|NAMES' || true
  fi
else
  echo "coolify não encontrado em $coolify_dir"
fi

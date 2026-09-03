#!/usr/bin/env bash

set -Eeuo pipefail

signoz_dir="${SIGNOZ_DIR:-/data/signoz}"
signoz_ui_port="${SIGNOZ_UI_PORT:-8081}"
foundry_bin="${FOUNDRY_BIN_PATH:-/usr/local/bin/foundryctl}"
postgres_collector_dir="${POSTGRES_COLLECTOR_DIR:-/data/signoz-integrations/postgres-collector}"
postgres_collector_container="${POSTGRES_COLLECTOR_CONTAINER:-espresso-postgres-collector}"

[[ "$signoz_ui_port" =~ ^[0-9]+$ ]] || die "SIGNOZ_UI_PORT deve ser numérica"

foundryctl_path() {
  if command -v foundryctl >/dev/null 2>&1; then
    command -v foundryctl
  elif [[ -x "$foundry_bin" ]]; then
    printf "%s\n" "$foundry_bin"
  else
    return 1
  fi
}

log "foundryctl"
if path="$(foundryctl_path)"; then
  echo "binário encontrado: $path"
  "$path" --help >/dev/null && echo "foundryctl executa corretamente"
else
  echo "foundryctl não instalado"
fi

log "signoz"
if path_is_dir_as_root "$signoz_dir"; then
  echo "diretório encontrado: $signoz_dir"
  if path_is_file_as_root "$signoz_dir/casting.yaml"; then
    echo "casting encontrado: $signoz_dir/casting.yaml"
  else
    echo "casting não encontrado em $signoz_dir/casting.yaml"
  fi
else
  echo "signoz não encontrado em $signoz_dir"
fi

log "containers"
if command -v docker >/dev/null 2>&1; then
  as_root docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -Ei 'NAMES|(^|[-_])(signoz|clickhouse|otel|zookeeper)' || true
else
  echo "docker não instalado"
fi

log "ui"
if command -v curl >/dev/null 2>&1; then
  if curl -fsS -o /dev/null --max-time 5 "http://127.0.0.1:${signoz_ui_port}/" 2>/dev/null; then
    echo "SigNoz UI respondeu em http://127.0.0.1:${signoz_ui_port}/"
  else
    echo "SigNoz UI não respondeu localmente em http://127.0.0.1:${signoz_ui_port}/"
  fi
else
  echo "curl não instalado"
fi

log "postgres collector"
if path_is_dir_as_root "$postgres_collector_dir"; then
  echo "diretório encontrado: $postgres_collector_dir"
  if path_is_file_as_root "$postgres_collector_dir/.env"; then
    echo ".env privado encontrado: $postgres_collector_dir/.env"
  else
    echo ".env privado não encontrado em $postgres_collector_dir/.env"
  fi
  if path_is_file_as_root "$postgres_collector_dir/collector.yaml"; then
    echo "collector.yaml encontrado"
  else
    echo "collector.yaml não encontrado"
  fi
  if path_is_file_as_root "$postgres_collector_dir/docker-compose.yml"; then
    echo "docker-compose.yml encontrado"
  else
    echo "docker-compose.yml não encontrado"
  fi
else
  echo "collector PostgreSQL não encontrado em $postgres_collector_dir"
fi

if command -v docker >/dev/null 2>&1; then
  if as_root docker inspect "$postgres_collector_container" >/dev/null 2>&1; then
    as_root docker ps --filter "name=^/${postgres_collector_container}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Networks}}'
    echo "logs recentes filtrados:"
    as_root docker logs --tail 80 "$postgres_collector_container" 2>&1 \
      | sed -E 's/(password[=:][^ ,}]+)/password=<redacted>/Ig; s#(postgresql://)[^@ ]+@#\1<redacted>@#Ig' \
      | grep -Ei 'error|warn|postgres|receiver|exporter' \
      | tail -20 || true
  else
    echo "container não encontrado: $postgres_collector_container"
  fi
fi

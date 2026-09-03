#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family

collector_enabled="${POSTGRES_COLLECTOR_ENABLED:-true}"
collector_dir="${POSTGRES_COLLECTOR_DIR:-/data/signoz-integrations/postgres-collector}"
collector_image="${POSTGRES_COLLECTOR_IMAGE:-otel/opentelemetry-collector-contrib:0.139.0}"
collector_container="${POSTGRES_COLLECTOR_CONTAINER:-espresso-postgres-collector}"
coolify_network="${POSTGRES_COLLECTOR_COOLIFY_NETWORK:-coolify}"
signoz_network="${POSTGRES_COLLECTOR_SIGNOZ_NETWORK:-signoz-network}"
signoz_endpoint="${POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT:-signoz-ingester:4317}"
coolify_project="${POSTGRES_COLLECTOR_COOLIFY_PROJECT:-espresso}"
postgres_container="${POSTGRES_COLLECTOR_POSTGRES_CONTAINER:-}"
postgres_host="${POSTGRES_COLLECTOR_POSTGRES_HOST:-}"
postgres_port="${POSTGRES_COLLECTOR_POSTGRES_PORT:-5432}"
postgres_db="${POSTGRES_COLLECTOR_POSTGRES_DB:-}"
monitor_user="${POSTGRES_MONITOR_USER:-espresso_otel_monitor}"
collection_interval="${POSTGRES_COLLECTOR_INTERVAL:-30s}"
deployment_environment="${POSTGRES_COLLECTOR_ENVIRONMENT:-production}"

env_file="$collector_dir/.env"
collector_config="$collector_dir/collector.yaml"
compose_file="$collector_dir/docker-compose.yml"

[[ "$postgres_port" =~ ^[0-9]+$ ]] || die "POSTGRES_COLLECTOR_POSTGRES_PORT deve ser numérica"
[[ "$monitor_user" =~ ^[A-Za-z_][A-Za-z0-9_]{0,62}$ ]] || die "POSTGRES_MONITOR_USER deve ser um identificador PostgreSQL simples"

reject_newline() {
  local name="$1"
  local value="$2"
  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    die "$name não pode conter quebra de linha"
  fi
}

for value_name in \
  collector_dir collector_image collector_container coolify_network signoz_network \
  signoz_endpoint coolify_project postgres_container postgres_host postgres_db \
  collection_interval deployment_environment; do
  reject_newline "$value_name" "${!value_name}"
done

if [[ "$collector_enabled" != "true" ]]; then
  log "POSTGRES_COLLECTOR_ENABLED=false; collector PostgreSQL ignorado"
  exit 0
fi

command -v docker >/dev/null 2>&1 || die "docker não encontrado; execute install:docker antes"
as_root docker compose version >/dev/null 2>&1 || die "docker compose plugin não encontrado"
service_is_active docker || die "serviço Docker não está ativo"

ensure_network_exists() {
  local network="$1"
  if ! as_root docker network inspect "$network" >/dev/null 2>&1; then
    die "rede Docker não encontrada: $network"
  fi
}

read_env_value() {
  local key="$1"
  local file="$2"
  if ! path_is_file_as_root "$file"; then
    return 1
  fi
  as_root awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; found = 1; exit } END { exit found ? 0 : 1 }' "$file"
}

generate_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
  fi
}

resolve_postgres_container() {
  if [[ -n "$postgres_container" ]]; then
    if ! as_root docker inspect "$postgres_container" >/dev/null 2>&1; then
      die "container PostgreSQL informado não encontrado: $postgres_container"
    fi
    if [[ "$(as_root docker inspect -f '{{.State.Running}}' "$postgres_container")" != "true" ]]; then
      die "container PostgreSQL informado não está em execução: $postgres_container"
    fi
    printf "%s\n" "$postgres_container"
    return
  fi

  local filter_args=(
    --filter "label=coolify.managed=true"
    --filter "label=coolify.database.subType=standalone-postgresql"
  )

  if [[ -n "$coolify_project" ]]; then
    filter_args+=(--filter "label=coolify.projectName=$coolify_project")
  fi

  local matches
  matches="$(as_root docker ps "${filter_args[@]}" --format '{{.Names}}')"
  local count
  count="$(printf "%s\n" "$matches" | awk 'NF { count++ } END { print count + 0 }')"

  case "$count" in
    0)
      die "container PostgreSQL da aplicação não encontrado; configure POSTGRES_COLLECTOR_POSTGRES_CONTAINER"
      ;;
    1)
      printf "%s\n" "$matches" | awk 'NF { print; exit }'
      ;;
    *)
      die "mais de um container PostgreSQL do Coolify encontrado; configure POSTGRES_COLLECTOR_POSTGRES_CONTAINER"
      ;;
  esac
}

read_postgres_container_env() {
  local container="$1"
  as_root docker exec "$container" sh -lc 'printf "%s\n%s\n" "${POSTGRES_USER:-postgres}" "${POSTGRES_DB:-postgres}"'
}

write_private_env() {
  local password="$1"
  local tmp
  tmp="$(as_root mktemp "$collector_dir/.env.XXXXXX")"
  as_root chmod 0600 "$tmp"
  as_root tee "$tmp" >/dev/null <<ENV
POSTGRES_MONITOR_USER=$monitor_user
POSTGRES_MONITOR_PASSWORD=$password
POSTGRES_DB_HOST=$postgres_host
POSTGRES_DB_PORT=$postgres_port
POSTGRES_DB_NAME=$postgres_db
POSTGRES_COLLECTOR_IMAGE=$collector_image
POSTGRES_COLLECTOR_CONTAINER=$collector_container
POSTGRES_COLLECTOR_COOLIFY_NETWORK=$coolify_network
POSTGRES_COLLECTOR_SIGNOZ_NETWORK=$signoz_network
SIGNOZ_OTLP_ENDPOINT=$signoz_endpoint
POSTGRES_COLLECTOR_INTERVAL=$collection_interval
POSTGRES_COLLECTOR_ENVIRONMENT=$deployment_environment
ENV
  as_root mv "$tmp" "$env_file"
  as_root chmod 0600 "$env_file"
}

apply_monitor_role() {
  local container="$1"
  local admin_user="$2"
  local admin_db="$3"
  local password="$4"

  log "criando ou reconciliando usuário monitor no PostgreSQL via container $container"
  as_root docker exec -i \
    -e MONITOR_USER="$monitor_user" \
    -e MONITOR_PASSWORD="$password" \
    -e MONITOR_DB="$postgres_db" \
    "$container" sh -s -- "$admin_user" "$admin_db" <<'SH'
set -Eeuo pipefail

admin_user="$1"
admin_db="$2"

export PGOPTIONS="-c espresso.monitor_user=${MONITOR_USER} -c espresso.monitor_password=${MONITOR_PASSWORD} -c espresso.monitor_db=${MONITOR_DB}"

psql -v ON_ERROR_STOP=1 -U "$admin_user" -d "$admin_db" <<'SQL'
DO $do$
DECLARE
  monitor_user text := current_setting('espresso.monitor_user');
  monitor_password text := current_setting('espresso.monitor_password');
  monitor_db text := current_setting('espresso.monitor_db');
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = monitor_user) THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', monitor_user, monitor_password);
  ELSE
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', monitor_user, monitor_password);
    EXECUTE format('ALTER ROLE %I WITH LOGIN', monitor_user);
  END IF;

  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', monitor_db, monitor_user);
  EXECUTE format('GRANT SELECT ON pg_catalog.pg_stat_database TO %I', monitor_user);
END
$do$;
SQL
SH
}

validate_monitor_connection() {
  local container="$1"
  local password="$2"

  log "validando conexão do usuário monitor no PostgreSQL"
  as_root docker exec \
    -e MONITOR_USER="$monitor_user" \
    -e MONITOR_DB="$postgres_db" \
    -e PGPASSWORD="$password" \
    "$container" sh -lc 'psql -v ON_ERROR_STOP=1 -h 127.0.0.1 -U "$MONITOR_USER" -d "$MONITOR_DB" -Atc "select count(*) from pg_catalog.pg_stat_database;" >/dev/null'
}

write_collector_config() {
  as_root tee "$collector_config" >/dev/null <<'YAML'
receivers:
  postgresql/espresso:
    endpoint: ${env:POSTGRES_DB_HOST}:${env:POSTGRES_DB_PORT}
    transport: tcp
    username: ${env:POSTGRES_MONITOR_USER}
    password: ${env:POSTGRES_MONITOR_PASSWORD}
    databases:
      - ${env:POSTGRES_DB_NAME}
    collection_interval: ${env:POSTGRES_COLLECTOR_INTERVAL}
    tls:
      insecure: true
    connection_pool:
      max_idle: 2
      max_open: 5

processors:
  resource/postgres:
    attributes:
      - key: service.name
        value: espresso-postgres
        action: upsert
      - key: deployment.environment
        value: ${env:POSTGRES_COLLECTOR_ENVIRONMENT}
        action: upsert
  batch:

exporters:
  otlp/signoz:
    endpoint: ${env:SIGNOZ_OTLP_ENDPOINT}
    tls:
      insecure: true

service:
  pipelines:
    metrics/postgres:
      receivers: [postgresql/espresso]
      processors: [resource/postgres, batch]
      exporters: [otlp/signoz]
YAML
  as_root chmod 0644 "$collector_config"
}

write_compose_file() {
  as_root tee "$compose_file" >/dev/null <<'YAML'
name: espresso-postgres-collector

services:
  postgres-collector:
    container_name: ${POSTGRES_COLLECTOR_CONTAINER}
    image: ${POSTGRES_COLLECTOR_IMAGE}
    command:
      - --config=/etc/otelcol-contrib/collector.yaml
      - --feature-gates=receiver.postgresql.separateSchemaAttr
    env_file:
      - .env
    restart: unless-stopped
    volumes:
      - ./collector.yaml:/etc/otelcol-contrib/collector.yaml:ro
    networks:
      coolify:
      signoz:

networks:
  coolify:
    external: true
    name: ${POSTGRES_COLLECTOR_COOLIFY_NETWORK}
  signoz:
    external: true
    name: ${POSTGRES_COLLECTOR_SIGNOZ_NETWORK}
YAML
  as_root chmod 0644 "$compose_file"
}

ensure_network_exists "$coolify_network"
ensure_network_exists "$signoz_network"

resolved_postgres_container="$(resolve_postgres_container)"
log "container PostgreSQL alvo: $resolved_postgres_container"

mapfile -t postgres_env < <(read_postgres_container_env "$resolved_postgres_container")
postgres_admin_user="${postgres_env[0]:-postgres}"
postgres_admin_db="${postgres_env[1]:-postgres}"

if [[ -z "$postgres_db" ]]; then
  postgres_db="$postgres_admin_db"
fi

if [[ -z "$postgres_host" ]]; then
  postgres_host="$resolved_postgres_container"
fi

reject_newline "postgres_host" "$postgres_host"
reject_newline "postgres_db" "$postgres_db"

as_root install -d -m 0700 "$collector_dir"

monitor_password="$(read_env_value POSTGRES_MONITOR_PASSWORD "$env_file" || true)"
if [[ -z "$monitor_password" ]]; then
  log "gerando senha do usuário monitor no .env privado do collector"
  monitor_password="$(generate_password)"
else
  log "senha existente do usuário monitor encontrada no .env privado do collector"
fi
reject_newline "POSTGRES_MONITOR_PASSWORD" "$monitor_password"
if [[ "$monitor_password" == *[[:space:]]* ]]; then
  die "POSTGRES_MONITOR_PASSWORD no .env privado não pode conter espaços"
fi

write_private_env "$monitor_password"
apply_monitor_role "$resolved_postgres_container" "$postgres_admin_user" "$postgres_admin_db" "$monitor_password"
validate_monitor_connection "$resolved_postgres_container" "$monitor_password"

write_collector_config
write_compose_file

log "validando configuração Docker Compose do collector PostgreSQL"
as_root docker compose --env-file "$env_file" -f "$compose_file" config --quiet

log "subindo ou atualizando collector PostgreSQL"
as_root docker compose --env-file "$env_file" -f "$compose_file" up -d

as_root docker ps --filter "name=^/${collector_container}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Networks}}'
log "collector PostgreSQL provisionado ou verificado com sucesso"

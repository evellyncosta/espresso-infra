#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family
require_apt

enable_ufw="${ENABLE_UFW:-true}"
enable_signoz_firewall="${ENABLE_SIGNOZ_FIREWALL:-true}"
signoz_ui_port="${SIGNOZ_UI_PORT:-8081}"

[[ "$signoz_ui_port" =~ ^[0-9]+$ ]] || die "SIGNOZ_UI_PORT deve ser numérica"

if [[ "$enable_ufw" != "true" ]]; then
  log "ENABLE_UFW=false; configuração de firewall do SigNoz ignorada"
  exit 0
fi

if [[ "$enable_signoz_firewall" != "true" ]]; then
  log "ENABLE_SIGNOZ_FIREWALL=false; portas do SigNoz não serão abertas"
  exit 0
fi

if ! command -v ufw >/dev/null 2>&1; then
  log "instalando ufw"
  as_root apt-get update
  apt_install ufw
fi

for port in "$signoz_ui_port" 4317 4318; do
  log "liberando porta ${port}/tcp para SigNoz"
  as_root ufw allow "${port}/tcp" comment "SigNoz observability"
done

as_root ufw status verbose
log "configuração de firewall do SigNoz concluída"

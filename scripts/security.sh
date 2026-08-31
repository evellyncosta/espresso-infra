#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family
require_apt

enable_ufw="${ENABLE_UFW:-true}"
ssh_port="${BOOTSTRAP_SSH_PORT:-22}"

[[ "$ssh_port" =~ ^[0-9]+$ ]] || die "BOOTSTRAP_SSH_PORT deve ser numérica"

if [[ "$enable_ufw" != "true" ]]; then
  log "ENABLE_UFW=false; configuração de firewall ignorada"
  exit 0
fi

if ! command -v ufw >/dev/null 2>&1; then
  log "instalando ufw"
  as_root apt-get update
  apt_install ufw
fi

log "configurando políticas padrão do ufw"
as_root ufw default deny incoming
as_root ufw default allow outgoing

log "liberando SSH antes de habilitar/recarregar firewall: ${ssh_port}/tcp"
as_root ufw allow "${ssh_port}/tcp" comment "SSH bootstrap"

for port in 80 443 8000 6001 6002; do
  log "liberando porta ${port}/tcp"
  as_root ufw allow "${port}/tcp" comment "Coolify bootstrap"
done

log "habilitando ufw de forma não interativa"
as_root ufw --force enable
as_root ufw status verbose

log "configuração de firewall concluída"

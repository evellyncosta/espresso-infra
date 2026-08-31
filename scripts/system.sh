#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family
require_apt

log "atualizando índice de pacotes"
as_root apt-get update

log "instalando dependências básicas"
apt_install ca-certificates curl gnupg lsb-release ufw openssl git jq

if [[ -n "${BOOTSTRAP_TIMEZONE:-}" ]]; then
  if command -v timedatectl >/dev/null 2>&1; then
    current_timezone="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
    if [[ "$current_timezone" != "$BOOTSTRAP_TIMEZONE" ]]; then
      log "configurando timezone: $BOOTSTRAP_TIMEZONE"
      as_root timedatectl set-timezone "$BOOTSTRAP_TIMEZONE"
    else
      log "timezone já configurado: $BOOTSTRAP_TIMEZONE"
    fi
  else
    log "timedatectl não encontrado; timezone não foi alterado"
  fi
fi

log "preparação do sistema concluída"

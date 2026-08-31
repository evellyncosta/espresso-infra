#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family
require_apt

# shellcheck disable=SC1091
source /etc/os-release

if command -v snap >/dev/null 2>&1 && snap list docker >/dev/null 2>&1; then
  die "Docker instalado via snap não é suportado pelo Coolify. Remova-o manualmente antes de continuar."
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  log "Docker e Compose já instalados; verificando serviço"
  as_root systemctl enable --now docker
  docker --version
  docker compose version
  systemctl is-active docker
  log "Docker já está pronto"
  exit 0
fi

log "instalando dependências do repositório Docker"
as_root apt-get update
apt_install ca-certificates curl gnupg

log "configurando chave e repositório oficial do Docker"
as_root install -m 0755 -d /etc/apt/keyrings

docker_gpg="/etc/apt/keyrings/docker.gpg"
if [[ ! -f "$docker_gpg" ]]; then
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | as_root gpg --dearmor -o "$docker_gpg"
  as_root chmod a+r "$docker_gpg"
fi

architecture="$(dpkg --print-architecture)"
codename="${VERSION_CODENAME:-}"
[[ -n "$codename" ]] || die "VERSION_CODENAME não encontrado em /etc/os-release"

repo_line="deb [arch=${architecture} signed-by=${docker_gpg}] https://download.docker.com/linux/${ID} ${codename} stable"
printf "%s\n" "$repo_line" | as_root tee /etc/apt/sources.list.d/docker.list >/dev/null

log "instalando Docker Engine e Compose plugin"
as_root apt-get update
apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "habilitando serviço Docker"
as_root systemctl enable --now docker

if [[ -n "${BOOTSTRAP_SSH_USER:-}" && "$BOOTSTRAP_SSH_USER" != "root" ]]; then
  if id "$BOOTSTRAP_SSH_USER" >/dev/null 2>&1; then
    as_root usermod -aG docker "$BOOTSTRAP_SSH_USER"
    log "usuário $BOOTSTRAP_SSH_USER adicionado ao grupo docker; novo login pode ser necessário"
  fi
fi

docker --version
docker compose version
systemctl is-active docker

log "instalação do Docker concluída"

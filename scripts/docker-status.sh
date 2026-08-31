#!/usr/bin/env bash

set -Eeuo pipefail

command -v docker >/dev/null 2>&1 || die "docker não encontrado"
docker --version
docker compose version
systemctl is-active docker

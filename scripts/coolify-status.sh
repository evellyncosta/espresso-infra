#!/usr/bin/env bash

set -Eeuo pipefail

coolify_dir="${COOLIFY_EXPECTED_DIR:-/data/coolify/source}"

path_is_dir_as_root "$coolify_dir" || die "diretório do Coolify não encontrado: $coolify_dir"
command -v docker >/dev/null 2>&1 || die "docker não encontrado"

as_root docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '^coolify|NAMES'

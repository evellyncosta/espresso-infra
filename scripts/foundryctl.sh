#!/usr/bin/env bash

set -Eeuo pipefail

require_debian_family
require_apt

install_url="${FOUNDRY_INSTALL_URL:-https://signoz.io/foundry.sh}"
foundry_version="${FOUNDRY_VERSION:-}"
foundry_bin="${FOUNDRY_BIN_PATH:-/usr/local/bin/foundryctl}"
foundry_bin_dir="$(dirname -- "$foundry_bin")"

foundryctl_path() {
  if command -v foundryctl >/dev/null 2>&1; then
    command -v foundryctl
  elif [[ -x "$foundry_bin" ]]; then
    printf "%s\n" "$foundry_bin"
  else
    return 1
  fi
}

verify_foundryctl() {
  local path="$1"
  "$path" --help >/dev/null
  log "foundryctl disponível em $path"
}

if path="$(foundryctl_path)"; then
  verify_foundryctl "$path"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  log "instalando curl para baixar o Foundry/foundryctl"
  as_root apt-get update
  apt_install ca-certificates curl
fi

log "instalando Foundry/foundryctl em $foundry_bin_dir"
as_root install -d -m 0755 "$foundry_bin_dir"

install_env=(XDG_BIN_HOME="$foundry_bin_dir")
if [[ -n "$foundry_version" ]]; then
  install_env+=(FOUNDRY_VERSION="$foundry_version")
fi

curl -fsSL "$install_url" | as_root env "${install_env[@]}" bash

if path="$(foundryctl_path)"; then
  verify_foundryctl "$path"
else
  die "foundryctl não encontrado após instalação"
fi

log "instalação do Foundry/foundryctl concluída"

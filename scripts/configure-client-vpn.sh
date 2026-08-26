#!/usr/bin/env bash

set -Eeuo pipefail

die() {
  echo "Erro: $*" >&2
  exit 1
}

command -v pulumi >/dev/null 2>&1 || die "pulumi não encontrado no PATH."
command -v aws >/dev/null 2>&1 || die "aws não encontrado no PATH."
command -v openssl >/dev/null 2>&1 || die "openssl não encontrado no PATH."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/.." && pwd)"
cd "$project_dir"

stack_name="${PULUMI_STACK:-$(pulumi stack --show-name 2>/dev/null || true)}"
[[ -n "$stack_name" ]] || die "Nenhum stack Pulumi selecionado. Execute 'pulumi stack select <stack>'."

pulumi_args=(--stack "$stack_name")
endpoint_id="$(pulumi stack output client_vpn_endpoint_id "${pulumi_args[@]}" 2>/dev/null || true)"
[[ "$endpoint_id" =~ ^cvpn-endpoint-[a-z0-9]+$ ]] || die "Não encontrei um client_vpn_endpoint_id válido no stack '$stack_name'."

region="$(pulumi config get aws:region "${pulumi_args[@]}" 2>/dev/null || true)"
if [[ -z "$region" ]]; then
  region="$(aws configure get region 2>/dev/null || true)"
fi
[[ -n "$region" ]] || die "Não encontrei a região AWS no Pulumi nem no AWS CLI."

endpoint_status="$(aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids "$endpoint_id" \
  --region "$region" \
  --query 'ClientVpnEndpoints[0].Status.Code' \
  --output text)"
[[ "$endpoint_status" == "available" ]] || die "O endpoint '$endpoint_id' está '$endpoint_status', não 'available'."

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/espresso"
profile_path="${ESPRESSO_CLIENT_VPN_PROFILE:-$config_dir/espresso-client-vpn.ovpn}"
client_cert="${ESPRESSO_CLIENT_VPN_CERT:-$config_dir/easy-rsa/pki/issued/local-client.crt}"
client_key="${ESPRESSO_CLIENT_VPN_KEY:-$config_dir/easy-rsa/pki/private/local-client.key}"

[[ -f "$client_cert" ]] || die "Certificado do cliente não encontrado: $client_cert"
[[ -f "$client_key" ]] || die "Chave do cliente não encontrada: $client_key"

openssl x509 -in "$client_cert" -noout >/dev/null 2>&1 \
  || die "O certificado não é válido: $client_cert"
openssl pkey -in "$client_key" -noout >/dev/null 2>&1 \
  || die "A chave privada não é válida ou está protegida por senha: $client_key"

mkdir -p "$config_dir"
mkdir -p "$(dirname -- "$profile_path")"
chmod 700 "$config_dir"

raw_profile="$(mktemp "${TMPDIR:-/tmp}/espresso-client-vpn.XXXXXX.ovpn")"
cleanup() {
  rm -f -- "$raw_profile"
}
trap cleanup EXIT

aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id "$endpoint_id" \
  --region "$region" \
  --output text \
  > "$raw_profile"

profile_tmp="$(mktemp "${TMPDIR:-/tmp}/espresso-client-vpn-profile.XXXXXX")"
trap 'rm -f -- "$raw_profile" "$profile_tmp"' EXIT

{
  sed -e '/^[[:space:]]*cert[[:space:]]/d' -e '/^[[:space:]]*key[[:space:]]/d' "$raw_profile"
  printf '\n<cert>\n'
  sed 's/\r$//' "$client_cert"
  printf '</cert>\n\n<key>\n'
  sed 's/\r$//' "$client_key"
  printf '</key>\n'
} > "$profile_tmp"

if [[ -f "$profile_path" ]]; then
  backup_path="${profile_path}.backup.$(date +%Y%m%d%H%M%S)"
  cp -- "$profile_path" "$backup_path"
  chmod 600 "$backup_path"
  echo "Perfil anterior preservado em: $backup_path"
fi

mv -- "$profile_tmp" "$profile_path"
chmod 600 "$profile_path" "$client_key"

echo "Perfil AWS Client VPN configurado com sucesso."
echo "Stack: $stack_name"
echo "Endpoint: $endpoint_id"
echo "Região: $region"
echo "Arquivo para importar no AWS Client VPN: $profile_path"

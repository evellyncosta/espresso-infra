## Why

O painel e os serviços administrativos do Coolify, assim como o SSH da VPS, não devem permanecer expostos à Internet após a configuração inicial. A infraestrutura já usa WireGuard para acesso administrativo, e a decisão e o procedimento precisam ser registrados para preservar a política de exposição e permitir sua operação segura.

## What Changes

- Adicionar a ADR 002 para formalizar que SSH e as portas administrativas do Coolify são acessíveis somente pela VPN WireGuard.
- Adicionar um manual operacional dedicado que descreve firewall da Contabo, WireGuard, UFW, validação e a retirada segura do acesso público.
- Referenciar o manual com um link Markdown explícito na ADR e incluir a ADR 002 no índice de ADRs.
- Atualizar a documentação de Coolify para indicar que o acesso administrativo direto depende da VPN e apontar para o manual.

## Capabilities

### New Capabilities

- Nenhuma. Esta é uma mudança exclusivamente documental; não altera requisitos de comportamento do sistema.

### Modified Capabilities

- Nenhuma.

## Impact

- Adiciona a ADR `docs/adrs/002-coolify-access-via-vpn.md` e o manual `docs/coolify-vpn-access.md`.
- Atualiza o índice em `docs/adrs/README.md` e a documentação existente em `docs/coolify.md`.
- Não executa nem altera regras de firewall, configuração WireGuard, chaves, credenciais ou recursos da Contabo.

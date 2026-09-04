## Why

As decisões de infraestrutura do Espresso Infra ainda não possuem um registro padronizado, o que dificulta recuperar o contexto e os limites de escolhas feitas para a VPS Contabo. A criação prévia de uma Private Network torna oportuno registrar seu propósito antes que futuras máquinas passem a depender dela.

## What Changes

- Criar uma área `docs/adrs/` para registrar decisões arquiteturais.
- Adicionar um índice com a convenção de numeração e status das ADRs.
- Adicionar um template reutilizável para novas ADRs.
- Registrar a ADR 001, que estabelece a Private Network da Contabo como rede de comunicação interna para futuras VPSs e serviços.
- Adicionar um link curto do README para a área de ADRs.

## Capabilities

### New Capabilities

- Nenhuma. Esta é uma mudança exclusivamente documental; os requisitos de comportamento do sistema não são alterados.

### Modified Capabilities

- Nenhuma.

## Impact

- Adiciona documentos Markdown sob `docs/adrs/` e uma referência no `README.md`.
- Não altera Taskfile, scripts, firewall, recursos da Contabo, endereços, rotas, credenciais ou chaves.
- A decisão esclarece que a Private Network não substitui o WireGuard para acesso administrativo remoto.

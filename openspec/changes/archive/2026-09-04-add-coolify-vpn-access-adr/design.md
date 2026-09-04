## Context

O repositório já mantém ADRs versionadas em `docs/adrs/`, com a ADR 001 distinguindo a Private Network da Contabo do WireGuard. A documentação de Coolify ainda descreve acesso direto pelo host e porta `8000`, sem registrar a política final de restrição administrativa. Consulte a motivação em [proposal.md](proposal.md).

## Goals / Non-Goals

**Goals:**

- Registrar a ADR 002 com a decisão de exposição pública limitada a HTTP, HTTPS e WireGuard.
- Criar um procedimento reproduzível e seguro para a transição, incluindo validações antes de fechar portas administrativas.
- Ligar a decisão ao procedimento com link Markdown relativo e navegável.
- Usar somente endereços, chaves e hosts exemplificativos, nunca valores reais.

**Non-Goals:**

- Executar comandos na VPS, no painel Contabo ou no computador do operador.
- Alterar Taskfile, automatizar UFW/WireGuard, ou modificar a configuração em execução.
- Definir uma política de acesso para serviços não listados, como SigNoz.

## Decisions

### A ADR 002 referencia um manual operacional dedicado

A ADR terá caráter duradouro: contexto, decisão, alternativas, consequências e critérios de revisão. Ela conterá um link Markdown explícito para `../coolify-vpn-access.md`, que preserva o passo a passo detalhado de firewall, WireGuard, UFW, testes e remoção de acesso público.

Alternativa considerada: concentrar toda a sequência de comandos na ADR. Rejeitada porque mistura decisão arquitetural com instruções operacionais extensas e dificulta a manutenção do procedimento.

### O manual usa uma transição em duas fases

O procedimento primeiro mantém SSH e Coolify acessíveis enquanto instala e valida o WireGuard. Somente após confirmar handshake, acesso ao painel e SSH pela rede da VPN, remove as permissões públicas no UFW e no firewall da Contabo. A política final deixa `80/tcp`, `443/tcp` e `51820/udp` públicos e permite `22/tcp`, `8000/tcp`, `6001/tcp` e `6002/tcp` exclusivamente à sub-rede WireGuard de exemplo `10.66.66.0/24`.

Alternativa considerada: bloquear as portas administrativas antes da validação. Rejeitada porque pode causar perda de acesso à VPS.

### A documentação existente de Coolify aponta para a política final

`docs/coolify.md` deixará claro que o painel e as portas diretas administrativas são acessados pela VPN no ambiente configurado e apontará ao manual. Isto evita que sua seção de acesso inicial seja interpretada como autorização de exposição pública permanente.

Alternativa considerada: não alterar a documentação atual. Rejeitada porque manteria instruções aparentemente conflitantes sobre o acesso direto por IP.

## Risks / Trade-offs

- [Fechar SSH ou Coolify antes de validar a VPN] → ordenar o manual para validar `wg`, HTTP privado e SSH privado antes da remoção das regras públicas.
- [Confundir a sub-rede WireGuard com a Private Network da Contabo] → declarar explicitamente que são redes distintas e que a faixa apresentada é exemplo da configuração WireGuard.
- [Expor dados de acesso] → usar placeholders para IP público e chaves, e reforçar que chaves privadas não saem de seus dispositivos.
- [Regressão por documentação divergente] → revisar os links relativos e a terminologia entre ADR, índice, manual e `docs/coolify.md`.

## Migration Plan

1. Criar o manual operacional em `docs/coolify-vpn-access.md` a partir do conteúdo fornecido, com exemplos não sensíveis.
2. Criar a ADR 002 em `docs/adrs/002-coolify-access-via-vpn.md`, incluindo link Markdown para o manual.
3. Incluir a ADR no índice `docs/adrs/README.md` e atualizar `docs/coolify.md` com o link de orientação.
4. Validar que todos os links internos apontam para arquivos existentes e que o texto não contém credenciais, chaves ou endereços reais.

Não há migração de runtime nem rollback operacional nesta mudança documental. Caso o conteúdo precise ser revertido, reverter somente os documentos e links criados ou alterados em um commit posterior; nenhuma configuração de infraestrutura será afetada.

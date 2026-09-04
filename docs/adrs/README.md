# Decisões Arquiteturais (ADRs)

Este diretório registra decisões arquiteturais duradouras do Espresso Infra. Uma ADR preserva o contexto, a decisão tomada e suas consequências, para que mudanças futuras possam avaliar ou revisar a escolha de forma explícita.

Voltar para o [README](../../README.md).

## Convenção

- Cada ADR usa o nome `NNN-resumo-da-decisao.md`, em que `NNN` é um número sequencial de três dígitos.
- A numeração é permanente: uma ADR substituída não é renumerada nem removida.
- Novas ADRs devem partir do [template](template.md) e indicar data e status.
- O texto não deve incluir credenciais, chaves, endereços reais de rede, identificadores da conta ou outros dados sensíveis.

## Status

| Status | Significado |
| --- | --- |
| Proposto | Está em discussão e ainda não orienta a infraestrutura. |
| Aceito | É a decisão vigente e deve orientar mudanças futuras. |
| Substituído | Foi sucedido por outra ADR, que deve ser referenciada. |
| Deprecado | Deixou de ser recomendado, sem uma decisão substituta imediata. |

## Índice

| ADR | Status | Decisão |
| --- | --- | --- |
| [001](001-private-network-contabo.md) | Aceito | Usar a Private Network da Contabo para comunicação interna futura. |

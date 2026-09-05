## Why

O Espresso Infra ainda versiona e executa o ciclo de vida do SigNoz e do collector PostgreSQL, embora esses componentes sejam uma plataforma de observabilidade independente do Coolify e da infraestrutura base. O repositório `espresso-observability` já foi criado para assumir essa responsabilidade e precisa se tornar a única fonte operacional da área.

## What Changes

- **BREAKING** Remover do Espresso Infra as tasks, scripts, variáveis de ambiente, documentação operacional e specs vigentes que provisionam ou descrevem SigNoz, Foundry/foundryctl e o collector PostgreSQL.
- Criar no `espresso-observability` uma base operacional independente com tasks de instalação, status, firewall e destruição, além de sua documentação operacional; o novo repositório não recebe specs ou ADRs históricos.
- Manter no Espresso Infra somente referências navegáveis ao repositório externo `https://github.com/evellyncosta/espresso-observability` e aos seus limites de integração com VPS, Docker, Coolify e PostgreSQL.
- Validar o novo ownership destruindo a instalação existente, instalando-a pelo repositório novo e destruindo-a novamente, deixando a VPS sem observabilidade para uma execução posterior do operador.

## Capabilities

### New Capabilities

- `observability-repository-boundary`: Define a fronteira entre o Espresso Infra e o repositório externo de observabilidade, incluindo os contratos de integração e a ausência de lifecycle operacional de observabilidade no infra.

### Modified Capabilities

- `infra-documentation`: Substitui a documentação detalhada de SigNoz e collector por referências ao repositório externo de observabilidade.

## Impact

- Remove o include `observability` do `Taskfile.yml`, `tasks/observability.yml` e os scripts remotos de SigNoz, Foundry, firewall, status e collector.
- Remove as variáveis de observabilidade de `.env.example` e de `scripts/remote.sh`.
- Move e adapta documentos operacionais para `/home/evellyn/projetos/espresso-observability`; o infra preserva apenas a documentação de sua própria responsabilidade e links externos.
- Remove do infra as specs-base `signoz-observability` e `postgres-observability-collector`; o histórico arquivado permanece no infra e não é copiado para o novo repositório.
- A task `destroy` do novo repositório afeta somente recursos de observabilidade na VPS e não pode alterar Coolify, PostgreSQL da aplicação, Docker base ou dados da aplicação.

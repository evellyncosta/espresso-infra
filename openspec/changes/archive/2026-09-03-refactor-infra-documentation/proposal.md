## Why

A documentacao atual concentra visao geral, operacao, variaveis, portas e detalhes de observabilidade no README, o que dificulta encontrar rapidamente a informacao certa para operar a infraestrutura. Com SigNoz, Coolify, collector PostgreSQL e a aplicacao em repositorio separado, o projeto precisa de uma estrutura de documentacao mais navegavel e com responsabilidades claras.

## What Changes

- Refatorar o `README.md` para atuar como overview geral do Espresso Infra, com quickstart curto e sumario para a documentacao detalhada.
- Criar uma pasta publica `docs/` para documentacao operacional e arquitetural detalhada.
- Mover detalhes de Coolify para um Markdown dedicado.
- Mover detalhes de SigNoz/Foundry, portas OTLP, firewall e limites operacionais para um Markdown dedicado.
- Renomear e ajustar a documentacao do collector PostgreSQL para um Markdown dedicado em `docs/`.
- Adicionar documentacao minima da aplicacao Espresso API, referenciando o repositorio externo `https://github.com/evellyncosta/espresso-api` e a fronteira entre aplicacao e infraestrutura.
- Consolidar comandos, tasks, variaveis e fluxos recorrentes em documentacao operacional dedicada.
- Atualizar links internos para evitar referencias quebradas apos a reorganizacao.

## Capabilities

### New Capabilities

- `infra-documentation`: Estrutura, navegacao e conteudo minimo da documentacao da infraestrutura, incluindo README, docs dedicados, Coolify, SigNoz, collector PostgreSQL e relacao com o repositorio externo da aplicacao.

### Modified Capabilities

- Nenhuma.

## Impact

- Afeta `README.md`, `architecture.md`, `postgres_collector_archtecture.md` e novos arquivos Markdown sob `docs/`.
- Nao altera scripts, Taskfile, infraestrutura provisionada, APIs, dependencias ou comportamento runtime.
- Melhora a operabilidade ao separar overview, arquitetura, Coolify, SigNoz, aplicacao, collector PostgreSQL e comandos operacionais.

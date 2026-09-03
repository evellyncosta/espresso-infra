## Context

See `proposal.md` for motivation. O estado atual tem `README.md` com mais de 300 linhas combinando overview, variaveis, tasks, portas, Coolify, SigNoz e collector PostgreSQL. Tambem existem `architecture.md` e `postgres_collector_archtecture.md` soltos na raiz, sendo que o segundo tem typo no nome e trata de um detalhe especifico de observabilidade.

A refatoracao deve ser apenas documental: nao deve alterar tasks, scripts, variaveis, portas, comportamento remoto ou infraestrutura provisionada.

## Goals / Non-Goals

**Goals:**

- Deixar o README curto e navegavel como entrada geral do projeto.
- Criar uma estrutura publica `docs/` para documentos detalhados.
- Separar documentacao por responsabilidade operacional: aplicacao, Coolify, SigNoz, collector PostgreSQL, operacao e arquitetura.
- Documentar a aplicacao Espresso API como repositorio externo com fronteiras claras entre aplicacao e infra.
- Corrigir a organizacao dos documentos existentes sem perder conteudo operacional relevante.

**Non-Goals:**

- Nao alterar implementacao do Taskfile, scripts shell, UFW, Docker, Coolify, SigNoz ou collector PostgreSQL.
- Nao documentar internals do repositorio da aplicacao que nao estejam conhecidos neste repo.
- Nao configurar instrumentacao, dashboards, alertas, API keys ou secrets do SigNoz.
- Nao criar automacao de validacao de links nesta change, a menos que ela ja exista no projeto.

## Decisions

### Usar `docs/` como raiz publica da documentacao detalhada

A implementacao deve criar `docs/` e mover a documentacao detalhada para essa pasta. A pasta `.docs/` existente nao deve ser usada como destino principal porque o prefixo sugere material interno ou auxiliar, nao documentacao publica do projeto.

Alternativa considerada: manter documentos detalhados na raiz. Isso preservaria caminhos curtos, mas manteria a raiz crescendo com documentos especificos e reduziria a clareza do README como entrada unica.

### Manter o README como overview e sumario

O README deve manter somente informacao suficiente para entender o projeto e executar o primeiro fluxo: proposta, limites, pre-requisitos, configuracao local minima, quickstart e links. Tabelas longas de variaveis, listas extensas de portas e detalhes de SigNoz/Coolify devem ir para documentos dedicados.

Alternativa considerada: manter todas as informacoes no README com melhor organizacao por headings. Isso ainda deixaria o arquivo grande e aumentaria duplicacao quando os detalhes evoluirem.

### Estruturar documentos por responsabilidade

Estrutura alvo:

```text
README.md
docs/
  architecture.md
  application.md
  coolify.md
  signoz.md
  postgres-collector.md
  operations.md
```

- `docs/architecture.md`: visao geral, diagramas e limites arquiteturais.
- `docs/application.md`: repositorio externo da aplicacao, responsabilidades, dependencias runtime e fronteira com a infra.
- `docs/coolify.md`: acesso, portas diretas, responsabilidades e servicos gerenciados.
- `docs/signoz.md`: Foundry/foundryctl, instalacao opt-in, portas, OTLP, firewall, memoria e limites.
- `docs/postgres-collector.md`: fluxo dedicado do collector PostgreSQL, substituindo `postgres_collector_archtecture.md`.
- `docs/operations.md`: tasks, variaveis, fluxos de provisionamento, status e operacao recorrente.

Alternativa considerada: criar um documento unico `docs/observability.md` para SigNoz e collector PostgreSQL. A separacao e melhor porque SigNoz e a plataforma de observabilidade, enquanto o collector PostgreSQL e uma integracao operacional especifica com credencial e topologia proprias.

### Tratar a aplicacao como fronteira externa documentada

`docs/application.md` deve apontar para `https://github.com/evellyncosta/espresso-api`, mas deve evitar afirmar detalhes internos nao verificados do repositorio da aplicacao. O conteudo minimo pode se basear no que este repo ja assume: aplicacao Spring gerenciada pelo Coolify, uso de PostgreSQL, Redis/Valkey e telemetria via SigNoz/OTLP.

Alternativa considerada: omitir a aplicacao por estar em outro repo. Isso deixaria uma lacuna operacional, porque a infraestrutura existe para executar a aplicacao e operadores precisam entender essa fronteira.

## Risks / Trade-offs

- Links antigos para `architecture.md` ou `postgres_collector_archtecture.md` podem quebrar -> Atualizar referencias internas e considerar stubs de redirecionamento se houver consumidores externos conhecidos.
- Documentacao pode duplicar variaveis entre README e `docs/operations.md` -> README deve manter apenas exemplos minimos e apontar para a lista completa.
- O repositorio da aplicacao pode estar privado, redirecionar ou mudar de nome -> Documentar o link fornecido pelo projeto e descrever apenas a fronteira conhecida pela infra.
- Mover arquivos pode dificultar diff review -> Fazer a refatoracao em passos claros: criar `docs/`, mover conteudo, reduzir README, revisar links.

## Migration Plan

1. Criar `docs/` com os documentos alvo.
2. Mover o conteudo de `architecture.md` para `docs/architecture.md` e ajustar links.
3. Mover e renomear `postgres_collector_archtecture.md` para `docs/postgres-collector.md`, preservando conteudo relevante e corrigindo o nome.
4. Extrair do README as secoes detalhadas de Coolify, SigNoz, variaveis, portas e tasks para `docs/coolify.md`, `docs/signoz.md` e `docs/operations.md`.
5. Criar `docs/application.md` com documentacao minima da aplicacao externa.
6. Reescrever o README como overview, quickstart e sumario.
7. Verificar links internos e confirmar que nomes antigos nao ficam referenciados indevidamente.

Rollback e um revert Git normal, pois a change nao altera runtime nem estado remoto.

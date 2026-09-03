## Why

O SigNoz já está provisionado como stack de observabilidade, mas o PostgreSQL gerenciado pelo Coolify ainda não possui coleta própria de métricas operacionais. Precisamos de um collector dedicado para integrar esse banco ao SigNoz sem acoplar a configuração ao ciclo de vida do Postgres no Coolify nem ao collector interno gerado pelo Foundry.

## What Changes

- Adicionar uma capacidade para provisionar um OpenTelemetry Collector dedicado para métricas do PostgreSQL da aplicação Espresso.
- Criar um usuário de monitoramento no Postgres da aplicação por meio do container gerenciado pelo Coolify, usando senha gerada e persistida somente na VPS.
- Executar o collector como uma stack Docker Compose separada, conectada às redes Docker `coolify` e `signoz-network`.
- Exportar métricas do receiver `postgresql` para o `signoz-ingester` via OTLP.
- Documentar o fluxo do collector, incluindo criação de credencial, topologia Docker, operação, status e limites de escopo.
- Criar `postgres_collector_archtecture.md` ao lado de `architecture.md` para explicar somente esse fluxo.

## Capabilities

### New Capabilities

- `postgres-observability-collector`: Provisionamento e operação de um collector dedicado para coletar métricas do PostgreSQL gerenciado pelo Coolify e enviá-las ao SigNoz.

### Modified Capabilities

- Nenhuma.

## Impact

- `Taskfile.yml` e `tasks/observability.yml` deverão expor task pública para instalar/verificar o collector do PostgreSQL.
- `scripts/` deverá ganhar script remoto para preparar o `.env` operacional privado na VPS, aplicar essa credencial no PostgreSQL via container gerenciado pelo Coolify, gerar configuração e subir a stack Compose do collector.
- `.env.example` deverá incluir variáveis não sensíveis para habilitação, diretório, imagem, container/rede alvo, banco e usuário monitor.
- `README.md` e `architecture.md` deverão ser atualizados para referenciar o collector e apontar para a documentação dedicada.
- Um novo arquivo `postgres_collector_archtecture.md` deverá ser criado na raiz do repositório, ao lado de `architecture.md`, contendo o desenho específico do fluxo Postgres -> collector -> SigNoz.
- A VPS deverá armazenar senha e arquivos operacionais do collector fora do repositório, em diretório privado.

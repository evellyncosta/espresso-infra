# SigNoz

Este documento descreve a observabilidade self-hosted com SigNoz na infraestrutura do Espresso.

Voltar para o [README](../README.md). Consulte também [Arquitetura](architecture.md), [Aplicação Espresso API](application.md), [Collector PostgreSQL](postgres-collector.md) e [Operação](operations.md).

## Papel do SigNoz

SigNoz recebe e apresenta telemetria da aplicação e de integrações operacionais. Neste repositório, ele é provisionado separadamente do Coolify usando Foundry/foundryctl.

O fluxo é opt-in para evitar instalar uma stack pesada durante o provisionamento base:

```bash
task setup:observability
```

Também é possível executar por etapas:

```bash
task install:foundryctl
task observability:firewall
task install:signoz
task observability:status
```

## Foundry/foundryctl

O caminho de instalação usa Foundry/foundryctl. O SigNoz usa `/data/signoz` por padrão. O arquivo `casting.yaml` é a fonte da verdade da instalação, e os arquivos gerados pelo Foundry em `pours/` não devem ser editados manualmente.

Variáveis principais:

| Variável | Padrão | Descrição |
| --- | --- | --- |
| `FOUNDRY_INSTALL_URL` | `https://signoz.io/foundry.sh` | Instalador oficial do Foundry/foundryctl. |
| `FOUNDRY_VERSION` | vazio | Versão específica do Foundry/foundryctl. Quando vazio, usa a latest do instalador. |
| `FOUNDRY_BIN_PATH` | `/usr/local/bin/foundryctl` | Caminho do binário `foundryctl` na VPS. |
| `SIGNOZ_DIR` | `/data/signoz` | Diretório do `casting.yaml` e arquivos gerados pelo Foundry. |
| `SIGNOZ_UI_PORT` | `8081` | Porta pública da UI do SigNoz na VPS. O container continua usando `8080`. |
| `ENABLE_SIGNOZ_FIREWALL` | `true` | Abre portas públicas do SigNoz quando a task de firewall de observabilidade executa. |

## Acesso e endpoints

A UI do SigNoz fica disponível em:

```text
http://<SERVER_HOST>:8081
```

Endpoints esperados para a aplicação Spring enviar telemetria:

```text
OTLP gRPC: http://<SERVER_HOST>:4317
OTLP HTTP: http://<SERVER_HOST>:4318
```

Por padrão, o Foundry gera a UI do container na porta `8080`, mas este repositório aplica um patch no `casting.yaml` para expor a UI na porta `8081` da VPS, evitando conflito com outros serviços locais.

## Firewall

As portas `SIGNOZ_UI_PORT`, `4317` e `4318` são abertas pela task `observability:firewall`, chamada pelo fluxo `task setup:observability`, quando `ENABLE_SIGNOZ_FIREWALL=true`.

| Porta | Uso |
| --- | --- |
| `8081/tcp` ou `SIGNOZ_UI_PORT` | UI do SigNoz quando observabilidade é provisionada. |
| `4317/tcp` | OTLP gRPC do SigNoz quando observabilidade é provisionada. |
| `4318/tcp` | OTLP HTTP do SigNoz quando observabilidade é provisionada. |

Endpoints OTLP podem receber dados operacionais. Expor essas portas publicamente é uma decisão de infraestrutura e pode ser endurecida futuramente por política de firewall ou proxy.

## Requisito de memória

O SigNoz precisa de pelo menos 4GB de memória disponível para Docker. A task de instalação falha antes da primeira instalação quando a VPS está claramente abaixo desse requisito.

## Limites

Instrumentação da aplicação Spring, dashboards, alertas, retenção e API keys do SigNoz ficam fora deste repositório. Este repositório provisiona a infraestrutura necessária para receber telemetria.

O SigNoz MCP não é habilitado nesta versão. A porta padrão documentada para MCP é `8000`, que conflita com o acesso direto inicial ao dashboard do Coolify.

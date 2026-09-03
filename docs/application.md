# Aplicação Espresso API

Este documento descreve a relação operacional entre este repositório de infraestrutura e a aplicação Espresso API, uma API de pedidos em Kotlin/Spring usada como alvo do lab Espresso.

Voltar para o [README](../README.md). Consulte também [Coolify](coolify.md), [SigNoz](signoz.md), [Collector PostgreSQL](postgres-collector.md) e [Operação](operations.md).

## Repositório da aplicação

A aplicação vive em um repositório separado:

```text
https://github.com/evellyncosta/espresso-api
```

Esse link pode redirecionar conforme a configuração do GitHub, permissões ou autenticação do operador. Este repositório de infraestrutura não versiona o código da aplicação.

## Papel no lab

O Espresso é um lab de infraestrutura, observabilidade e performance. A Espresso API é o serviço de aplicação usado para exercitar esse ambiente: ela representa o domínio de pedidos, roda como API Kotlin/Spring e se conecta aos serviços de apoio provisionados ou gerenciados pela infraestrutura.

O objetivo operacional do lab é gerar carga, observar o comportamento da aplicação e coletar insights de runtime. k6 é a ferramenta esperada para cenários de carga e performance, enquanto SigNoz recebe os sinais de observabilidade.

## Fronteira de responsabilidades

| Área | Responsabilidade |
| --- | --- |
| `espresso-api` | Código da API de pedidos, build da aplicação, configuração funcional, instrumentação, cenários k6 quando aplicável e uso de dependências externas. |
| Coolify | Integração com o repositório da aplicação, build/deploy, lifecycle do container, variáveis, domínio, HTTPS e serviços vinculados. |
| Espresso Infra | Preparação da VPS, Docker, firewall, Coolify, SigNoz opt-in e collector PostgreSQL dedicado. |
| SigNoz | Recebimento e visualização de métricas, traces e logs quando a observabilidade for provisionada. |

Este repo não deve duplicar o deploy da aplicação fora do Coolify nem armazenar secrets reais da aplicação.

## Runtime esperado

A infraestrutura assume que a aplicação Espresso é executada como uma API Kotlin/Spring gerenciada pelo Coolify. O Coolify é o ponto esperado para configurar:

- repositório Git da aplicação;
- build e deploy;
- variáveis de ambiente e secrets;
- domínio e HTTPS;
- container da aplicação;
- serviços PostgreSQL e Redis/Valkey quando usados pelo runtime.

## Dependências da aplicação

Dependências conhecidas pela infraestrutura:

- PostgreSQL gerenciado pelo Coolify;
- Redis/Valkey gerenciado pelo Coolify;
- SigNoz para telemetria quando `task setup:observability` for executado;
- k6 para geração de carga e coleta de insights de performance;
- integrações externas funcionais da aplicação, como S3, quando ainda forem usadas pela aplicação.

Configuração de nomes exatos de variáveis, credenciais e feature flags da aplicação deve ser mantida no Coolify ou no repositório `espresso-api`, não neste repo.

## Observabilidade da aplicação

Quando SigNoz estiver provisionado, a aplicação pode enviar telemetria para os endpoints expostos pela VPS:

```text
OTLP gRPC: http://<SERVER_HOST>:4317
OTLP HTTP: http://<SERVER_HOST>:4318
```

Se a aplicação estiver na mesma VPS e puder acessar a rede Docker adequada, uma configuração interna mais restrita pode ser adotada futuramente. A primeira documentação deste repo registra os endpoints públicos provisionados pelo firewall de observabilidade.

Instrumentação OpenTelemetry, dashboards, alertas, retenção, API keys e cenários k6 ficam fora deste repositório, salvo quando uma change específica do lab trouxer esse escopo para a infra.

## Banco e cache

O PostgreSQL e o Redis/Valkey da aplicação devem ter persistência configurada pelo Coolify/Docker. Eles não devem depender apenas da camada gravável efêmera dos containers.

O collector PostgreSQL documentado em [Collector PostgreSQL](postgres-collector.md) coleta métricas básicas do banco da aplicação sem publicar `5432` no host da VPS.

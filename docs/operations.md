# Operação

Este documento reúne tasks, variáveis, portas e fluxos recorrentes do Espresso Infra.

Voltar para o [README](../README.md). Consulte também [Arquitetura](architecture.md), [Coolify](coolify.md), [SigNoz](signoz.md), [Collector PostgreSQL](postgres-collector.md) e [Aplicação Espresso API](application.md).

## Configuração local

Crie o arquivo local de ambiente:

```bash
cp .env.example .env
```

Preencha as variáveis obrigatórias:

```env
SERVER_HOST=<IP_OU_HOSTNAME_DA_VPS>
SERVER_USER=<USUARIO_SSH>
SSH_KEY_PATH=<CAMINHO_DA_CHAVE_PRIVADA>
```

O arquivo `.env` é ignorado pelo Git. Não adicione chaves, senhas, tokens ou credenciais reais ao repositório.

## Variáveis disponíveis

| Variável | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- |
| `SERVER_HOST` | sim | vazio | IP ou hostname da VPS. |
| `SERVER_USER` | sim | vazio | Usuário usado na conexão SSH. |
| `SSH_KEY_PATH` | sim | vazio | Caminho local da chave SSH privada. |
| `SSH_PORT` | não | `22` | Porta SSH da VPS. |
| `BOOTSTRAP_TIMEZONE` | não | `America/Sao_Paulo` | Timezone aplicado no servidor quando informado. |
| `ENABLE_UFW` | não | `true` | Habilita configuração de firewall com UFW. |
| `COOLIFY_INSTALL_URL` | não | URL oficial do Coolify | Instalador self-hosted do Coolify. |
| `COOLIFY_EXPECTED_DIR` | não | `/data/coolify/source` | Diretório esperado da instalação do Coolify. |
| `FOUNDRY_INSTALL_URL` | não | `https://signoz.io/foundry.sh` | Instalador oficial do Foundry/foundryctl. |
| `FOUNDRY_VERSION` | não | vazio | Versão específica do Foundry/foundryctl. Quando vazio, usa a latest do instalador. |
| `FOUNDRY_BIN_PATH` | não | `/usr/local/bin/foundryctl` | Caminho do binário `foundryctl` na VPS. |
| `SIGNOZ_DIR` | não | `/data/signoz` | Diretório do `casting.yaml` e arquivos gerados pelo Foundry. |
| `SIGNOZ_UI_PORT` | não | `8081` | Porta pública da UI do SigNoz na VPS. O container continua usando `8080`. |
| `ENABLE_SIGNOZ_FIREWALL` | não | `true` | Abre portas públicas do SigNoz quando a task de firewall de observabilidade executa. |
| `POSTGRES_COLLECTOR_ENABLED` | não | `true` | Habilita a task dedicada do collector PostgreSQL. |
| `POSTGRES_COLLECTOR_DIR` | não | `/data/signoz-integrations/postgres-collector` | Diretório operacional privado do collector na VPS. |
| `POSTGRES_COLLECTOR_IMAGE` | não | `otel/opentelemetry-collector-contrib:0.139.0` | Imagem usada para executar o collector PostgreSQL. |
| `POSTGRES_COLLECTOR_CONTAINER` | não | `espresso-postgres-collector` | Nome do container do collector. |
| `POSTGRES_COLLECTOR_COOLIFY_NETWORK` | não | `coolify` | Rede Docker usada para acessar o PostgreSQL gerenciado pelo Coolify. |
| `POSTGRES_COLLECTOR_SIGNOZ_NETWORK` | não | `signoz-network` | Rede Docker usada para exportar métricas ao SigNoz. |
| `POSTGRES_COLLECTOR_SIGNOZ_ENDPOINT` | não | `signoz-ingester:4317` | Endpoint OTLP interno do SigNoz usado pelo collector. |
| `POSTGRES_COLLECTOR_COOLIFY_PROJECT` | não | `espresso` | Projeto Coolify usado para localizar automaticamente o container PostgreSQL. |
| `POSTGRES_COLLECTOR_POSTGRES_CONTAINER` | não | vazio | Container PostgreSQL alvo. Quando vazio, o script tenta detectar pelo Coolify. |
| `POSTGRES_COLLECTOR_POSTGRES_HOST` | não | vazio | Host usado pelo collector para acessar o PostgreSQL. Quando vazio, usa o container detectado. |
| `POSTGRES_COLLECTOR_POSTGRES_PORT` | não | `5432` | Porta interna do PostgreSQL. |
| `POSTGRES_COLLECTOR_POSTGRES_DB` | não | vazio | Banco alvo. Quando vazio, usa `POSTGRES_DB` do container PostgreSQL. |
| `POSTGRES_MONITOR_USER` | não | `espresso_otel_monitor` | Usuário de monitoramento criado no PostgreSQL da aplicação. |
| `POSTGRES_COLLECTOR_INTERVAL` | não | `30s` | Intervalo de coleta de métricas do PostgreSQL. |
| `POSTGRES_COLLECTOR_ENVIRONMENT` | não | `production` | Valor de `deployment.environment` nas métricas emitidas. |

## Provisionamento

Execute o fluxo completo:

```bash
task setup
```

O `setup` executa, em ordem:

1. validação local e conectividade SSH;
2. preparação do sistema operacional;
3. instalação/verificação do Docker;
4. configuração básica de firewall;
5. instalação/verificação do Coolify.

As tasks foram desenhadas para serem idempotentes. Reexecutar `task setup` deve preservar Docker, Coolify, firewall e dados persistentes existentes.

## Observabilidade

Provisionamento opt-in de observabilidade:

```bash
task setup:observability
```

Instalação dedicada do collector PostgreSQL:

```bash
task install:postgres-collector
```

Veja [SigNoz](signoz.md) e [Collector PostgreSQL](postgres-collector.md) para os detalhes desses fluxos.

## Tasks disponíveis

Liste as tasks públicas:

```bash
task --list
```

Principais comandos:

```bash
task preflight
task ssh:test
task system
task security
task install:docker
task install:coolify
task install:foundryctl
task install:signoz
task install:postgres-collector
task setup:observability
task observability:firewall
task observability:install-postgres-collector
task observability:status
task status
task setup
```

## Portas

As tasks de firewall usam UFW e liberam explicitamente:

| Porta | Uso |
| --- | --- |
| `22/tcp` ou `SSH_PORT` | SSH usado no provisionamento. |
| `80/tcp` | HTTP, proxy e emissão/renovação de certificados. |
| `443/tcp` | HTTPS. |
| `8000/tcp` | Acesso direto inicial ao dashboard do Coolify. |
| `6001/tcp` | Atualizações em tempo real do dashboard quando acessado por IP direto. |
| `6002/tcp` | Terminal web por IP direto. |
| `8081/tcp` ou `SIGNOZ_UI_PORT` | UI do SigNoz quando observabilidade é provisionada. |
| `4317/tcp` | OTLP gRPC do SigNoz quando observabilidade é provisionada. |
| `4318/tcp` | OTLP HTTP do SigNoz quando observabilidade é provisionada. |

Depois que o dashboard estiver configurado por domínio/proxy no Coolify, as portas diretas `8000`, `6001` e `6002` podem ser restringidas ou fechadas conforme a política operacional do ambiente.

As portas `SIGNOZ_UI_PORT`, `4317` e `4318` são abertas pela task `observability:firewall`, chamada pelo fluxo `task setup:observability`, quando `ENABLE_SIGNOZ_FIREWALL=true`.

## Persistência

Este repositório não cria volume externo na Contabo. Dados persistentes devem usar o filesystem da própria VPS por meio de:

- Docker volumes gerenciados pelo Docker/Coolify;
- bind mounts explícitos no filesystem da VPS quando necessário.

PostgreSQL, Redis/Valkey e dados da aplicação não devem depender apenas da camada gravável efêmera dos containers. Backup e migração automática de dados de produção estão fora do escopo desta etapa.

## Dependências AWS

O caminho operacional anterior em Pulumi/AWS foi removido deste repositório porque era exclusivo da hospedagem antiga. A classificação feita para esta migração foi:

| Item anterior | Classificação |
| --- | --- |
| Pulumi project e dependências Python | Runtime AWS antigo. |
| VPC, subnets, route tables e VPC endpoints | Rede AWS antiga. |
| Security groups e Client VPN | Acesso privado AWS antigo. |
| RDS PostgreSQL e Secrets Manager associado | Banco gerenciado AWS antigo, substituído por serviço gerenciado via Coolify quando aplicável. |
| ElastiCache/Valkey | Cache gerenciado AWS antigo, substituído por serviço gerenciado via Coolify quando aplicável. |
| ECR, ECS Express Mode, IAM task roles e CloudWatch logs | Runtime de aplicação AWS antigo. |

Integrações AWS funcionais da aplicação, como S3, não devem ser removidas automaticamente neste repositório caso ainda sejam usadas pela aplicação. Elas devem ser configuradas como dependências da aplicação no Coolify.

## Referências

- Coolify self-hosted installation: https://coolify.io/docs/get-started/installation
- Coolify firewall: https://next.coolify.io/docs/core/infrastructure/servers/firewall
- SigNoz Docker installation: https://signoz.io/docs/install/docker/
- Foundry getting started: https://github.com/SigNoz/foundry/blob/main/docs/getting-started.md
- Taskfile: https://taskfile.dev/

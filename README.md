# Espresso Infra

Provisionamento da infraestrutura do projeto Espresso usando Taskfile, Docker e Coolify.

Atualmente a infraestrutura roda em uma VPS Contabo já existente. Este repositório prepara essa VPS para executar a aplicação Espresso API e seus serviços de apoio, mas não cria, destrói, redimensiona nem gerencia o ciclo de vida da máquina no provedor. A VPS deve existir antes da execução das tasks, com acesso SSH funcional a partir da máquina do operador.

## Proposta do projeto

O Espresso Infra entrega uma interface operacional via Taskfile para preparar o servidor remoto por SSH, validar o sistema operacional, configurar dependências básicas, proteger o acesso inicial com UFW, instalar Docker e instalar ou preservar o Coolify.

A partir do Coolify, a infraestrutura de runtime passa a incluir a Espresso API, uma API de pedidos em Kotlin/Spring, PostgreSQL e Redis/Valkey em containers gerenciados. Observabilidade com SigNoz é provisionada em um fluxo separado e opt-in, usando Foundry/foundryctl fora do ciclo de vida do Coolify.

O foco é reduzir a complexidade operacional da hospedagem sem introduzir outro sistema de provisionamento. Este repositório não chama APIs da Contabo, não usa Pulumi, Terraform, OpenTofu, Ansible, Chef ou Puppet, e não tenta gerenciar recursos externos à VPS.

## Espresso como lab

O Espresso é um lab de infraestrutura, observabilidade e performance. A aplicação usada no ambiente é a Espresso API, uma API de pedidos escrita em Kotlin/Spring e mantida em um repositório separado: `https://github.com/evellyncosta/espresso-api`.

O ambiente do lab contém:

- uma API Kotlin/Spring para o domínio de pedidos;
- PostgreSQL como banco relacional da aplicação;
- Redis/Valkey como cache ou serviço de apoio;
- Coolify para deploy e lifecycle dos containers;
- SigNoz para receber e visualizar métricas, traces e logs;
- k6 como ferramenta esperada para gerar carga e coletar insights de performance.

O objetivo é executar a aplicação em uma infraestrutura pequena e controlada, gerar carga com k6 e observar o comportamento do sistema por meio de métricas e sinais de runtime. Este repositório prepara a infraestrutura necessária para esses experimentos; os scripts de teste, cenários k6 e instrumentação da aplicação pertencem ao escopo da aplicação ou de mudanças específicas do lab.

## Infraestrutura provisionada

O fluxo base `task setup` provisiona ou verifica:

- sistema operacional suportado para o runtime;
- pacotes básicos necessários para operação;
- firewall UFW com portas necessárias para SSH, HTTP, HTTPS e Coolify;
- Docker Engine e Docker Compose plugin;
- Coolify self-hosted;
- base para containers da API Kotlin/Spring, PostgreSQL e Redis/Valkey gerenciados pelo Coolify.

O fluxo opt-in `task setup:observability` provisiona Foundry/foundryctl e SigNoz self-hosted. O collector PostgreSQL para métricas do banco da aplicação é instalado por uma task dedicada.

## Pré-requisitos

- VPS já criada e configurada no provedor. Atualmente, o provedor usado é a Contabo.
- Debian 12, Ubuntu 22.04 LTS ou Ubuntu 24.04 LTS.
- Acesso SSH funcionando para a VPS.
- Usuário `root` ou usuário com `sudo` sem senha para comandos administrativos.
- Chave SSH privada válida e já configurada na máquina do desenvolvedor ou operador.
- Task instalado localmente: https://taskfile.dev/installation/
- Domínio apontado para a VPS quando o acesso HTTPS final for configurado no Coolify.

Evite instalar o Task via snap se ele falhar com `need to run as root or suid`. Nesse caso, instale o binário oficial do Task ou use outro método recomendado pela documentação.

## Configuração rápida

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

Execute o provisionamento base:

```bash
task setup
```

Execute observabilidade somente quando a VPS tiver capacidade e exposição de portas desejadas:

```bash
task setup:observability
task install:postgres-collector
```

Consulte a operação detalhada, variáveis e portas em [docs/operations.md](docs/operations.md).

## Acessos principais

Após a instalação, o acesso inicial ao painel do Coolify fica disponível em:

```text
http://<SERVER_HOST>:8000
```

Depois de configurar domínio e HTTPS pelo proxy do Coolify, o acesso normal deve passar pelas portas `80` e `443`.

Quando SigNoz for provisionado, a UI fica disponível por padrão em:

```text
http://<SERVER_HOST>:8081
```

## Documentação detalhada

- [Arquitetura](docs/architecture.md): visão geral dos componentes, fluxos e limites arquiteturais.
- [Aplicação Espresso API](docs/application.md): relação com o repositório externo da aplicação e suas dependências de runtime.
- [Coolify](docs/coolify.md): acesso, responsabilidades, portas diretas e serviços gerenciados.
- [SigNoz](docs/signoz.md): Foundry/foundryctl, instalação opt-in, portas, OTLP, firewall e limites.
- [Collector PostgreSQL](docs/postgres-collector.md): fluxo PostgreSQL -> collector -> SigNoz, credencial privada e validação.
- [Operação](docs/operations.md): tasks, variáveis, portas, persistência, escopo e referências.
- [Decisões arquiteturais (ADRs)](docs/adrs/README.md): decisões duradouras e seus contextos.

## Responsabilidades

| Área | Responsabilidade |
| --- | --- |
| VPS Contabo | Existir previamente e aceitar acesso SSH administrativo. |
| Espresso Infra | Preparar sistema, firewall, Docker, Coolify, SigNoz opt-in e integrações operacionais documentadas. |
| Coolify | Gerenciar deploy, variáveis, domínio, certificados, API Kotlin/Spring, PostgreSQL e Redis/Valkey. |
| SigNoz | Receber telemetria e disponibilizar observabilidade self-hosted quando instalado. |
| Espresso API | Implementar a API de pedidos em Kotlin/Spring e configurar suas dependências funcionais, telemetria e cenários de carga quando aplicável. |

## Fora de escopo

- Criar, excluir, redimensionar ou alterar plano da VPS Contabo.
- Usar Pulumi, Terraform, OpenTofu, Ansible, Chef ou Puppet.
- Provisionar volumes externos da Contabo.
- Migrar dados de produção automaticamente.
- Configurar CI/CD completo.
- Instrumentar a aplicação Kotlin/Spring com OpenTelemetry.
- Criar cenários de teste de carga com k6.
- Configurar dashboards, alertas, retenção ou API keys do SigNoz.
- Coletar query samples, top queries ou planos de query do PostgreSQL.
- Habilitar SigNoz MCP.
- Migrar logs históricos do CloudWatch.
- Implementar backup completo da infraestrutura.

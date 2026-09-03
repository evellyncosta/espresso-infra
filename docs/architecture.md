# Arquitetura

Este documento descreve a arquitetura do Espresso Infra e do ambiente provisionado para o projeto Espresso: componentes do repositório, fluxo de provisionamento, VPS, Coolify, containers da aplicação Spring, PostgreSQL, Redis/Valkey, SigNoz e persistência.

Voltar para o [README](../README.md). Consulte também [Aplicação Espresso API](application.md), [Coolify](coolify.md), [SigNoz](signoz.md), [Collector PostgreSQL](postgres-collector.md) e [Operação](operations.md).

## Visão geral

```mermaid
flowchart TD
    operator[Máquina do operador]
    taskfile[Taskfile]
    ssh[SSH]
    internet[Usuários / Internet]

    subgraph VPS[VPS Contabo atual]
        os[Debian 12 ou Ubuntu LTS]
        ufw[UFW]
        docker[Docker Engine e Compose]

        subgraph CoolifyPlatform[Coolify self-hosted]
            dashboard[Dashboard Coolify]
            proxy[Proxy HTTP/HTTPS]
            deploy[Build e deploy]
            services[Gerenciamento de serviços]
        end

        subgraph ObservabilityPlatform[SigNoz via Foundry]
            foundry[foundryctl]
            signozui[UI SigNoz :8081]
            otlpgrpc[OTLP gRPC :4317]
            otlphttp[OTLP HTTP :4318]
            pgcollector[Collector PostgreSQL]
        end

        subgraph ManagedContainers[Containers gerenciados pelo Coolify]
            spring[Aplicação Espresso Spring]
            postgres[PostgreSQL]
            redis[Redis/Valkey]
        end

        storage[Docker volumes ou bind mounts locais]
    end

    operator --> taskfile
    taskfile --> ssh
    ssh --> os
    os --> ufw
    os --> docker
    docker --> dashboard
    docker --> proxy
    docker --> deploy
    docker --> services
    docker --> foundry
    foundry --> signozui
    foundry --> otlpgrpc
    foundry --> otlphttp
    docker --> pgcollector
    deploy --> spring
    services --> postgres
    services --> redis
    internet --> proxy
    internet --> signozui
    spring --> otlpgrpc
    spring --> otlphttp
    pgcollector --> postgres
    pgcollector --> otlpgrpc
    proxy --> spring
    spring --> postgres
    spring --> redis
    postgres --> storage
    redis --> storage
    spring --> storage
```

## Componentes do repositório

```mermaid
flowchart LR
    root[Repositório espresso-infra]
    readme[README.md]
    docs[docs/]
    taskfile[Taskfile.yml]
    envexample[.env.example]
    taskmods[tasks/system.yml<br/>tasks/security.yml<br/>tasks/docker.yml<br/>tasks/coolify.yml<br/>tasks/observability.yml]
    remote[scripts/remote.sh]
    lib[scripts/server-lib.sh]
    scripts[scripts/system.sh<br/>scripts/security.sh<br/>scripts/docker.sh<br/>scripts/coolify.sh<br/>scripts/foundryctl.sh<br/>scripts/signoz.sh<br/>scripts/postgres-collector.sh<br/>scripts/signoz-firewall.sh<br/>scripts/observability-status.sh<br/>scripts/status.sh]

    root --> readme
    root --> docs
    root --> taskfile
    root --> envexample
    taskfile --> taskmods
    taskmods --> remote
    remote --> lib
    remote --> scripts
```

## Fluxo de provisionamento

```mermaid
sequenceDiagram
    participant Operador
    participant Task as Taskfile
    participant Remote as scripts/remote.sh
    participant VPS as VPS Contabo
    participant Docker
    participant Coolify
    participant Foundry as Foundry/foundryctl
    participant SigNoz

    Operador->>Task: task setup
    Task->>Remote: preflight
    Remote->>VPS: valida SSH e variáveis obrigatórias
    Task->>Remote: system
    Remote->>VPS: valida SO, atualiza pacotes e aplica timezone
    Task->>Remote: docker
    Remote->>Docker: instala ou verifica Docker Engine e Compose
    Task->>Remote: security
    Remote->>VPS: configura UFW e libera portas necessárias
    Task->>Remote: coolify
    Remote->>Coolify: instala ou preserva instalação existente
    Coolify-->>Operador: dashboard disponível na VPS

    Operador->>Task: task setup:observability
    Task->>Remote: foundryctl
    Remote->>Foundry: instala ou preserva foundryctl
    Task->>Remote: signoz-firewall
    Remote->>VPS: libera 8081, 4317 e 4318 quando habilitado
    Task->>Remote: signoz
    Remote->>SigNoz: aplica casting.yaml via foundryctl cast
    SigNoz-->>Operador: UI disponível em 8081 e OTLP em 4317/4318

    Operador->>Task: task install:postgres-collector
    Task->>Remote: postgres-collector
    Remote->>Coolify: localiza container PostgreSQL da aplicação
    Remote->>VPS: cria .env privado do collector
    Remote->>Coolify: cria ou reconcilia usuário monitor no PostgreSQL
    Remote->>SigNoz: sobe collector e exporta métricas para signoz-ingester
```

## Runtime do software

```mermaid
flowchart TD
    user[Cliente HTTP]
    git[Repositório Git da aplicação Espresso]

    subgraph VPS[VPS Contabo]
        ufw[UFW: 80/443 e portas administrativas]

        subgraph CoolifyArea[Coolify]
            proxy[Proxy HTTP/HTTPS]
            builder[Build da aplicação]
            envvars[Variáveis e secrets]
            lifecycle[Ciclo de vida dos containers]
        end

        subgraph DockerRuntime[Docker runtime]
            app[Container Spring Espresso]
            db[Container PostgreSQL]
            cache[Container Redis/Valkey]
            appvol[Volume ou bind mount da aplicação]
            dbvol[Volume PostgreSQL]
            cachevol[Volume Redis/Valkey]
        end

        subgraph Observability[SigNoz]
            signoz[UI SigNoz]
            collector[OTel Collector]
            pgcollector[PostgreSQL Collector]
            signozstore[Volumes SigNoz]
        end
    end

    user --> ufw
    ufw --> proxy
    ufw --> signoz
    proxy --> app
    git --> builder
    builder --> app
    envvars --> app
    lifecycle --> app
    lifecycle --> db
    lifecycle --> cache
    app --> db
    app --> cache
    app --> collector
    db --> pgcollector
    pgcollector --> collector
    app --> appvol
    db --> dbvol
    cache --> cachevol
    collector --> signoz
    signoz --> signozstore
```

## Limites arquiteturais

```mermaid
flowchart LR
    infra[Espresso Infra]
    contabo[Contabo]
    apprepo[espresso-api]
    coolify[Coolify]
    spring[Aplicação Espresso Spring]
    postgres[PostgreSQL]
    pgcollector[PostgreSQL Collector]
    redis[Redis/Valkey]
    signoz[SigNoz]
    aws[AWS funcional externa quando necessária]

    contabo -- fornece a VPS atual --> infra
    apprepo -- fornece código da aplicação --> coolify
    infra -- provisiona SO, firewall, Docker e Coolify --> coolify
    infra -- provisiona Foundry/foundryctl e SigNoz --> signoz
    coolify -- gerencia container --> spring
    coolify -- gerencia serviço --> postgres
    coolify -- gerencia serviço --> redis
    infra -- provisiona collector dedicado --> pgcollector
    pgcollector -- lê métricas via usuário monitor --> postgres
    pgcollector -- exporta OTLP interno --> signoz
    spring -- envia telemetria --> signoz
    spring -- pode consumir --> aws
```

O Espresso Infra provisiona a base de infraestrutura na VPS: sistema operacional suportado, firewall, Docker, Coolify e observabilidade SigNoz quando o fluxo opt-in é executado. A VPS atual é da Contabo, mas o repositório assume que ela já existe e está acessível por SSH.

O ciclo de vida da aplicação Spring, do PostgreSQL, do Redis/Valkey, dos domínios, certificados e variáveis é gerenciado pelo Coolify. SigNoz é gerenciado separadamente pelo Foundry/foundryctl. O collector PostgreSQL é uma integração de observabilidade separada: ele usa um `.env` privado na VPS para criar ou reconciliar um usuário monitor no container PostgreSQL do Coolify e exporta métricas ao SigNoz pela rede Docker interna.

Integrações externas funcionais, como S3, permanecem dependências da aplicação quando existirem.

O fluxo completo do collector PostgreSQL está descrito em [Collector PostgreSQL](postgres-collector.md).

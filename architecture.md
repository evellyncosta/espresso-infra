# Arquitetura

Este documento descreve a arquitetura do Espresso Infra e do ambiente provisionado para o projeto Espresso: componentes do repositório, fluxo de provisionamento, VPS, Coolify, containers da aplicação Spring, PostgreSQL, Redis/Valkey e persistência.

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
    deploy --> spring
    services --> postgres
    services --> redis
    internet --> proxy
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
    taskfile[Taskfile.yml]
    envexample[.env.example]
    taskmods[tasks/system.yml<br/>tasks/security.yml<br/>tasks/docker.yml<br/>tasks/coolify.yml]
    remote[scripts/remote.sh]
    lib[scripts/server-lib.sh]
    scripts[scripts/system.sh<br/>scripts/security.sh<br/>scripts/docker.sh<br/>scripts/coolify.sh<br/>scripts/status.sh]

    root --> readme
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
    end

    user --> ufw
    ufw --> proxy
    proxy --> app
    git --> builder
    builder --> app
    envvars --> app
    lifecycle --> app
    lifecycle --> db
    lifecycle --> cache
    app --> db
    app --> cache
    app --> appvol
    db --> dbvol
    cache --> cachevol
```

## Limites arquiteturais

```mermaid
flowchart LR
    infra[Espresso Infra]
    contabo[Contabo]
    coolify[Coolify]
    spring[Aplicação Espresso Spring]
    postgres[PostgreSQL]
    redis[Redis/Valkey]
    aws[AWS funcional externa quando necessária]

    contabo -- fornece a VPS atual --> infra
    infra -- provisiona SO, firewall, Docker e Coolify --> coolify
    coolify -- gerencia container --> spring
    coolify -- gerencia serviço --> postgres
    coolify -- gerencia serviço --> redis
    spring -- pode consumir --> aws
```

O Espresso Infra provisiona a base de infraestrutura na VPS: sistema operacional suportado, firewall, Docker e Coolify. A VPS atual é da Contabo, mas o repositório assume que ela já existe e está acessível por SSH. O ciclo de vida da aplicação Spring, do PostgreSQL, do Redis/Valkey, dos domínios, certificados e variáveis é gerenciado pelo Coolify. Integrações externas funcionais, como S3, permanecem dependências da aplicação quando existirem.

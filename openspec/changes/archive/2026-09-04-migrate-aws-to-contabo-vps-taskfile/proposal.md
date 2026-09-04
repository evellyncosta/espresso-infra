## Por que

A infraestrutura atual foi desenhada para execução na AWS com Pulumi, ECS Express Mode, RDS, ElastiCache, ECR, CloudWatch, IAM e rede privada gerenciada. A aplicação será migrada para uma VPS Contabo já provisionada manualmente, exigindo um fluxo operacional simples para preparar o servidor sem gerenciar o ciclo de vida da máquina ou depender de IaC.

## O que muda

- Introduzir Taskfile como interface principal de bootstrap e operações iniciais da VPS.
- Adicionar automação remota via SSH para preparação do sistema operacional, segurança básica, Docker e Coolify.
- Adicionar `.env.example` com variáveis não sensíveis para conexão SSH e opções de bootstrap.
- Documentar pré-requisitos, variáveis, fluxo `task setup`, tasks públicas e responsabilidades de Coolify.
- Remover ou substituir dependências exclusivas da execução AWS quando não forem mais necessárias ao runtime na VPS.
- Garantir que o bootstrap não crie, destrua ou gerencie a VPS Contabo nem volumes externos.
- Preservar dependências AWS que continuem sendo serviços funcionais externos, como S3, caso a aplicação ainda precise delas.
- Definir persistência em Docker volumes ou bind mounts no filesystem da VPS, sem armazenamento apenas no filesystem efêmero dos containers.
- **BREAKING**: O repositório deixa de ter Pulumi/AWS como caminho operacional para preparar o ambiente de execução da aplicação.

## Capacidades

### Novas capacidades

- `contabo-vps-bootstrap`: Bootstrap operacional de uma VPS Contabo pré-provisionada via Taskfile, incluindo preparação do sistema, segurança básica, Docker, Coolify, variáveis, idempotência e documentação.

### Capacidades modificadas

- Nenhuma.

## Impacto

- A documentação principal do repositório deverá passar de AWS/Pulumi para o fluxo Contabo VPS + Taskfile + Coolify.
- A estrutura operacional deverá incluir `Taskfile.yml`, tasks modulares, scripts shell pequenos quando necessário e `.env.example`.
- O código Pulumi/AWS existente em `__main__.py`, `Pulumi.yaml`, `pyproject.toml`, `poetry.lock` e scripts específicos de AWS deverá ser removido ou isolado quando for exclusivo do runtime antigo.
- O script `scripts/configure-client-vpn.sh` e referências a ECS, ECR, CloudWatch, IAM, security groups, RDS, ElastiCache/Valkey e VPC endpoints deverão ser avaliados durante a implementação antes de remoção.
- O deploy da aplicação passará a ser responsabilidade do Coolify após o bootstrap inicial, não das tasks do repositório de infraestrutura.

# Espresso Infra

Provisionamento da infraestrutura do projeto Espresso usando Taskfile, Docker e Coolify.

Atualmente a infraestrutura roda em uma VPS Contabo. Este repositório prepara essa VPS para executar a aplicação Espresso e seus serviços de apoio, mas não cria, destrói, redimensiona nem gerencia o ciclo de vida da máquina no provedor. A VPS deve existir antes da execução das tasks, com acesso SSH funcional a partir da máquina do operador.

## Proposta do projeto

A proposta do Espresso Infra é provisionar a infraestrutura necessária para rodar o projeto Espresso em uma VPS já configurada, usando Taskfile como interface operacional e Coolify como plataforma de deploy e runtime de containers.

O projeto entrega uma interface única via Taskfile para preparar o servidor remoto por SSH, validar o sistema operacional, configurar dependências básicas, proteger o acesso inicial com UFW, instalar Docker e instalar ou preservar o Coolify. A partir do Coolify, a infraestrutura de runtime passa a incluir a aplicação Spring do Espresso, PostgreSQL e Redis/Valkey em containers gerenciados.

O foco é reduzir a complexidade operacional da hospedagem sem introduzir outro sistema de provisionamento. Por isso, este repositório não chama APIs da Contabo, não usa Pulumi, Terraform, OpenTofu, Ansible, Chef ou Puppet, e não tenta gerenciar recursos externos à VPS.

## Infraestrutura provisionada

O fluxo `task setup` provisiona ou verifica:

- sistema operacional suportado para o runtime;
- pacotes básicos necessários para operação;
- firewall UFW com as portas necessárias para SSH, HTTP, HTTPS e Coolify;
- Docker Engine e Docker Compose plugin;
- Coolify self-hosted;
- base para containers da aplicação Spring, PostgreSQL e Redis/Valkey gerenciados pelo Coolify.

## Documentação de arquitetura

A arquitetura do projeto está documentada separadamente em [architecture.md](architecture.md).

## Pré-requisitos

- VPS já criada e configurada no provedor. Atualmente, o provedor usado é a Contabo.
- Debian 12, Ubuntu 22.04 LTS ou Ubuntu 24.04 LTS.
- Acesso SSH funcionando para a VPS.
- Usuário `root` ou usuário com `sudo` sem senha para comandos administrativos.
- Chave SSH privada válida e já configurada na máquina do desenvolvedor ou operador.
- Task instalado localmente: https://taskfile.dev/installation/
- Domínio apontado para a VPS quando o acesso HTTPS final for configurado no Coolify.

Evite instalar o Task via snap se ele falhar com `need to run as root or suid`. Nesse caso, instale o binário oficial do Task ou use outro método recomendado pela documentação.

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

Variáveis disponíveis:

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

O arquivo `.env` é ignorado pelo Git. Não adicione chaves, senhas, tokens ou credenciais reais ao repositório.

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

## Acesso ao Coolify e à VPS

Após a instalação, o acesso inicial ao painel do Coolify fica disponível na porta `8000`:

```text
http://<SERVER_HOST>:8000
```

Depois de configurar domínio e HTTPS pelo proxy do Coolify, o acesso normal deve passar pelas portas `80` e `443`.

Para acessar a CLI da VPS:

```bash
ssh <SERVER_USER>@<SERVER_HOST>
```

Comandos úteis dentro da VPS:

```bash
sudo docker ps
cd /data/coolify/source
sudo docker exec -it coolify bash
```

O terminal web do Coolify é acessado pela interface do painel. Quando o painel é acessado diretamente por IP, ele depende da porta `6002/tcp`.

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
task status
task setup
```

## Portas

A task de segurança usa UFW e libera explicitamente:

| Porta | Uso |
| --- | --- |
| `22/tcp` ou `SSH_PORT` | SSH usado no provisionamento. |
| `80/tcp` | HTTP, proxy e emissão/renovação de certificados. |
| `443/tcp` | HTTPS. |
| `8000/tcp` | Acesso direto inicial ao dashboard do Coolify. |
| `6001/tcp` | Atualizações em tempo real do dashboard quando acessado por IP direto. |
| `6002/tcp` | Terminal web por IP direto. |

Depois que o dashboard estiver configurado por domínio/proxy no Coolify, as portas diretas `8000`, `6001` e `6002` podem ser restringidas ou fechadas conforme a política operacional do ambiente.

## Persistência

Este repositório não cria volume externo na Contabo. Dados persistentes devem usar o filesystem da própria VPS por meio de:

- Docker volumes gerenciados pelo Docker/Coolify;
- bind mounts explícitos no filesystem da VPS quando necessário.

PostgreSQL, Redis/Valkey e dados da aplicação não devem depender apenas da camada gravável efêmera dos containers. Backup e migração automática de dados de produção estão fora do escopo desta etapa.

## Responsabilidades do Coolify

Após o provisionamento, o Coolify é responsável por:

- integração com o repositório da aplicação;
- build e deploy;
- restart e lifecycle dos containers;
- variáveis de ambiente da aplicação;
- domínio, HTTP/HTTPS e certificados;
- container da aplicação Spring Espresso;
- PostgreSQL e Redis/Valkey quando esses serviços forem executados pelo Coolify;
- volumes persistentes dos serviços gerenciados.

O Taskfile não deve duplicar essas responsabilidades.

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

## Fora de escopo

- Criar, excluir, redimensionar ou alterar plano da VPS Contabo.
- Usar Pulumi, Terraform, OpenTofu, Ansible, Chef ou Puppet.
- Provisionar volumes externos da Contabo.
- Migrar dados de produção automaticamente.
- Configurar CI/CD completo.
- Implementar observabilidade, OpenTelemetry ou SigNoz.
- Migrar logs históricos do CloudWatch.
- Implementar backup completo da infraestrutura.

## Referências

- Coolify self-hosted installation: https://coolify.io/docs/get-started/installation
- Coolify firewall: https://next.coolify.io/docs/core/infrastructure/servers/firewall
- Taskfile: https://taskfile.dev/

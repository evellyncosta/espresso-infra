# signoz-observability Specification

## Purpose

Define o contrato operacional para provisionar observabilidade self-hosted na VPS do Espresso usando Foundry/foundryctl e SigNoz, sem transferir essa responsabilidade para o Coolify.

## Requirements

### Requirement: Configuração de observabilidade por variáveis de ambiente
O sistema SHALL permitir configurar a instalação de observabilidade por variáveis locais não sensíveis, mantendo valores sensíveis fora do controle de versão.

#### Scenario: Variáveis opcionais não informadas
- **WHEN** um operador executa as tasks de observabilidade sem configurar variáveis opcionais
- **THEN** o sistema usa padrões documentados para instalar Foundry/foundryctl e SigNoz em Docker Compose

#### Scenario: Diretório do SigNoz customizado
- **WHEN** um operador configura um diretório de instalação do SigNoz
- **THEN** as tasks de observabilidade usam esse diretório para o casting, arquivos gerados e estado operacional da stack

### Requirement: Instalação do Foundry/foundryctl
O sistema SHALL instalar ou verificar o `foundryctl` na VPS antes de instalar o SigNoz.

#### Scenario: foundryctl ausente
- **WHEN** a task de instalação do `foundryctl` executa em uma VPS suportada sem `foundryctl`
- **THEN** o `foundryctl` é instalado por um caminho suportado e sua execução é validada

#### Scenario: foundryctl já instalado
- **WHEN** a task de instalação do `foundryctl` executa em uma VPS onde `foundryctl` já está disponível
- **THEN** a task preserva a instalação existente e valida que o binário responde corretamente

### Requirement: Instalação do SigNoz self-hosted
O sistema SHALL instalar ou verificar o SigNoz self-hosted na VPS usando Foundry/foundryctl com Docker Compose.

#### Scenario: SigNoz ausente
- **WHEN** a task de instalação do SigNoz executa depois que Docker, Compose e `foundryctl` estão prontos
- **THEN** o SigNoz é provisionado com uma configuração declarativa de Foundry para Docker Compose

#### Scenario: SigNoz já instalado
- **WHEN** a task de instalação do SigNoz executa em uma VPS com uma instalação existente gerenciada pelo Foundry/foundryctl
- **THEN** a task preserva a configuração existente e verifica que a stack permanece operacional

### Requirement: Firewall para observabilidade
O sistema SHALL aplicar regras de firewall para permitir acesso às interfaces necessárias do SigNoz sem bloquear SSH, HTTP, HTTPS ou Coolify.

#### Scenario: Portas do SigNoz habilitadas
- **WHEN** a configuração de firewall de observabilidade executa
- **THEN** a interface web do SigNoz e os endpoints OTLP documentados ficam acessíveis conforme a política configurada

#### Scenario: Conflito de porta detectado
- **WHEN** uma porta necessária para SigNoz já está ocupada por outro serviço antes da instalação
- **THEN** a task falha com uma mensagem clara antes de alterar a instalação do SigNoz

### Requirement: Status operacional de observabilidade
O sistema SHALL expor uma task de status que permita verificar Foundry/foundryctl e a stack SigNoz remotamente.

#### Scenario: Status consultado
- **WHEN** um operador executa a task de status de observabilidade
- **THEN** a saída informa a versão ou disponibilidade do `foundryctl`, containers relevantes do SigNoz e o estado da interface web quando possível

### Requirement: Separação entre observabilidade e runtime da aplicação
O sistema SHALL manter SigNoz como componente de infraestrutura de observabilidade separado do ciclo de vida da aplicação gerenciado pelo Coolify.

#### Scenario: Aplicação Espresso gerenciada pelo Coolify
- **WHEN** a aplicação Spring, PostgreSQL e Redis/Valkey são gerenciados pelo Coolify
- **THEN** as tasks de observabilidade não substituem o deploy, restart, variáveis, domínio ou serviços da aplicação

#### Scenario: Aplicação envia telemetria
- **WHEN** a aplicação Espresso precisar enviar métricas, traces ou logs para SigNoz
- **THEN** a documentação informa os endpoints de coleta que devem ser usados pela configuração da aplicação

### Requirement: Documentação da observabilidade
O sistema SHALL documentar instalação, portas, requisitos mínimos, responsabilidades e limites operacionais do SigNoz.

#### Scenario: Operador lê documentação
- **WHEN** um operador se prepara para provisionar observabilidade
- **THEN** a documentação explica as novas tasks, variáveis, portas, requisito de memória, relação com Coolify e caminho esperado de acesso ao SigNoz

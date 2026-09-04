# contabo-vps-bootstrap Specification

## Purpose

Define o contrato operacional de bootstrap para preparar uma VPS Contabo provisionada manualmente para executar a aplicação com Docker e Coolify, usando Taskfile como interface local do desenvolvedor sem gerenciar o ciclo de vida da VPS.

## Requirements

### Requirement: Configuração do servidor por variáveis de ambiente
O sistema SHALL exigir que valores específicos de conexão com o servidor sejam fornecidos por configuração local de ambiente, e não hardcoded em tasks ou scripts.

#### Scenario: Variáveis obrigatórias do servidor informadas
- **WHEN** um desenvolvedor copia `.env.example` para `.env` e preenche `SERVER_HOST`, `SERVER_USER` e `SSH_KEY_PATH`
- **THEN** as tasks de bootstrap conseguem acessar a VPS configurada via SSH sem exigir valores sensíveis no controle de versão

#### Scenario: Variáveis obrigatórias do servidor ausentes
- **WHEN** um desenvolvedor executa uma task remota de bootstrap sem uma variável obrigatória de conexão
- **THEN** a task falha antes de alterar o servidor e informa a variável ausente

### Requirement: Interface pública de bootstrap via Taskfile
O sistema SHALL expor tasks públicas no Taskfile para listar e executar operações de bootstrap da VPS.

#### Scenario: Desenvolvedor lista as tasks disponíveis
- **WHEN** um desenvolvedor executa `task --list`
- **THEN** a saída inclui as tasks públicas de bootstrap e descrições curtas de sua finalidade

#### Scenario: Desenvolvedor executa o setup completo
- **WHEN** um desenvolvedor executa `task setup`
- **THEN** o sistema executa as etapas necessárias de bootstrap em uma ordem segura para uma VPS nova e suportada

### Requirement: Preparação remota do sistema
O sistema SHALL preparar um sistema operacional suportado da VPS com apenas os pacotes e configurações necessários para Docker, Coolify e operação segura.

#### Scenario: Servidor novo preparado
- **WHEN** a task de preparação do sistema executa em uma VPS nova compatível
- **THEN** os pacotes do sistema são atualizados, as dependências básicas necessárias são instaladas e o timezone configurado é aplicado quando fornecido

#### Scenario: Servidor não suportado falha claramente
- **WHEN** a task de preparação executa em um sistema operacional não suportado
- **THEN** a task falha com uma mensagem clara e não continua para a instalação do Docker ou do Coolify

### Requirement: Configuração de firewall segura para SSH
O sistema SHALL configurar regras básicas de firewall sem bloquear o acesso SSH usado durante o bootstrap.

#### Scenario: Firewall habilitado durante o bootstrap
- **WHEN** a task de segurança configura o firewall do servidor
- **THEN** SSH, HTTP, HTTPS e as portas documentadas necessárias para o Coolify permanecem liberadas

#### Scenario: Sessão SSH existente permanece utilizável
- **WHEN** regras de firewall são aplicadas via SSH
- **THEN** o caminho de acesso SSH ativo permanece permitido antes de o firewall ser habilitado ou recarregado

### Requirement: Instalação do runtime Docker
O sistema SHALL instalar e habilitar Docker como runtime de containers para cargas gerenciadas pelo Coolify.

#### Scenario: Docker ausente
- **WHEN** a task de instalação do Docker executa em uma VPS suportada sem Docker
- **THEN** Docker é instalado, habilitado para inicialização automática e iniciado com sucesso

#### Scenario: Docker já instalado
- **WHEN** a task de instalação do Docker executa em uma VPS onde Docker já está instalado
- **THEN** a task preserva a instalação existente e verifica que o serviço Docker está ativo

### Requirement: Instalação do Coolify
O sistema SHALL instalar o Coolify na VPS preparada e deixá-lo operacional para o deploy da aplicação.

#### Scenario: Coolify ausente
- **WHEN** a task de instalação do Coolify executa depois que Docker está ativo
- **THEN** Coolify é instalado usando seu fluxo de instalação suportado e fica acessível pelo caminho documentado

#### Scenario: Coolify já instalado
- **WHEN** a task de instalação do Coolify executa em uma VPS com instalação existente do Coolify
- **THEN** a task preserva a instalação e verifica que o Coolify permanece operacional

### Requirement: Sem gerenciamento de ciclo de vida da VPS ou volume externo
O sistema SHALL NOT criar, destruir, redimensionar ou gerenciar de qualquer outra forma a VPS Contabo ou um volume Contabo separado.

#### Scenario: Bootstrap executado
- **WHEN** qualquer task de bootstrap ou setup é executada
- **THEN** nenhuma chamada à API da Contabo é feita para criar, destruir, redimensionar ou anexar recursos de VPS ou volume

#### Scenario: Armazenamento persistente necessário
- **WHEN** dados persistentes de containers são necessários
- **THEN** o sistema usa Docker volumes ou bind mounts no filesystem da VPS em vez de provisionar um volume externo do provedor

### Requirement: Coolify responsável pelo ciclo de vida da aplicação
O sistema SHALL manter deploy normal da aplicação, restart, gerenciamento de variáveis de ambiente, configuração de domínio e gerenciamento de serviços sob responsabilidade do Coolify após o bootstrap.

#### Scenario: Bootstrap concluído
- **WHEN** `task setup` termina com sucesso
- **THEN** deploys subsequentes da aplicação podem ser feitos pelo Coolify sem reexecutar o bootstrap completo da VPS

#### Scenario: Serviços da aplicação definidos
- **WHEN** PostgreSQL, Redis ou containers da aplicação são necessários para o ambiente de execução
- **THEN** eles são gerenciados pelo Coolify com armazenamento persistente Docker em vez de duplicados como tasks de ciclo de vida da aplicação gerenciadas pelo Taskfile

### Requirement: Remoção de dependências AWS de runtime
O sistema SHALL remover ou substituir dependências de infraestrutura exclusivas da AWS que não sejam mais necessárias ao caminho de deploy na VPS Contabo.

#### Scenario: Recursos exclusivos do runtime AWS presentes
- **WHEN** a implementação avalia artefatos de ECS, ECR, CloudWatch, IAM roles, security groups, VPC endpoints, RDS, ElastiCache ou Client VPN
- **THEN** recursos usados exclusivamente pelo caminho antigo de runtime AWS são removidos ou substituídos pela abordagem VPS/Coolify

#### Scenario: AWS permanece como serviço externo funcional
- **WHEN** uma integração AWS ainda é necessária pela aplicação independentemente da hospedagem do runtime
- **THEN** a integração é preservada e documentada como dependência da aplicação em vez de removida como código de infraestrutura de hospedagem

### Requirement: Execução idempotente do bootstrap
O sistema SHALL tornar as tasks de bootstrap seguras para execução repetida, sem perda de dados ou configuração duplicada.

#### Scenario: Setup reexecutado após sucesso
- **WHEN** um desenvolvedor executa `task setup` após uma execução anterior bem-sucedida
- **THEN** Docker, Coolify, firewall e configuração de dados persistentes existentes são preservados, e a execução não falha apenas porque os componentes já existem

#### Scenario: Etapa obrigatória falha
- **WHEN** uma etapa de bootstrap falha de forma que impede continuação segura
- **THEN** o fluxo de setup para e informa a etapa responsável pela falha

### Requirement: Documentação do bootstrap
O sistema SHALL documentar pré-requisitos, configuração, tasks públicas e limites operacionais do bootstrap da VPS Contabo.

#### Scenario: Desenvolvedor lê a documentação do repositório
- **WHEN** um desenvolvedor se prepara para executar o bootstrap de uma VPS
- **THEN** a documentação explica ferramentas locais necessárias, acesso obrigatório à VPS, variáveis `.env`, `task setup`, `task --list`, responsabilidades do Coolify e operações fora de escopo

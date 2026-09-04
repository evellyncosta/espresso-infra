# postgres-observability-collector Specification

## Purpose

Define o contrato operacional para provisionar um collector dedicado que coleta métricas do PostgreSQL da aplicação Espresso gerenciado pelo Coolify e envia esses dados ao SigNoz, mantendo credenciais fora do repositório e preservando a separação entre observabilidade, banco e runtime da aplicação.

## Requirements

### Requirement: Configuração do collector por variáveis não sensíveis
O sistema SHALL permitir configurar o collector do PostgreSQL por variáveis locais não sensíveis, mantendo senhas e credenciais geradas fora do controle de versão e persistidas em um `.env` operacional privado na VPS.

#### Scenario: Variáveis opcionais ausentes
- **WHEN** um operador executa a instalação do collector sem informar variáveis opcionais
- **THEN** o sistema usa padrões documentados para diretório operacional, imagem do collector, usuário monitor, redes Docker e endpoint do SigNoz

#### Scenario: Configuração customizada
- **WHEN** um operador informa diretório, imagem, nome de container, rede Docker, host do Postgres ou nome do banco por variáveis
- **THEN** o sistema usa esses valores para provisionar ou verificar o collector

#### Scenario: Credenciais sensíveis
- **WHEN** o sistema precisa persistir a senha do usuário monitor
- **THEN** a senha é armazenada somente na VPS em um `.env` operacional privado do collector, sem ser gravada em arquivos rastreados pelo repositório

#### Scenario: Script remoto prepara ambiente operacional
- **WHEN** o operador executa a task de instalação ou verificação do collector
- **THEN** um script remoto na VPS cria ou verifica o diretório operacional do collector e o `.env` privado que contém a senha usada pelo usuário monitor do PostgreSQL

### Requirement: Criação de usuário monitor no PostgreSQL via container do Coolify
O sistema SHALL criar ou verificar um usuário dedicado de monitoramento entrando no container PostgreSQL da aplicação gerenciado pelo Coolify e aplicando a senha persistida no `.env` operacional privado da VPS.

#### Scenario: Usuário monitor ausente
- **WHEN** o collector é provisionado e o usuário monitor ainda não existe no PostgreSQL da aplicação
- **THEN** o sistema entra no container PostgreSQL gerenciado pelo Coolify e cria um usuário dedicado com login, senha lida do `.env` operacional privado e permissões mínimas necessárias para coletar métricas básicas

#### Scenario: Usuário monitor existente
- **WHEN** o collector é reprovisionado e o usuário monitor já existe
- **THEN** o sistema entra no container PostgreSQL gerenciado pelo Coolify e preserva ou reconcilia o usuário com a senha lida do `.env` operacional privado sem criar usuários duplicados

#### Scenario: Senha operacional ausente
- **WHEN** não existe senha persistida para o usuário monitor no diretório operacional do collector
- **THEN** o sistema gera uma senha nova, armazena essa senha com permissões restritas no `.env` operacional privado da VPS e aplica a mesma senha ao usuário monitor no PostgreSQL por meio do container gerenciado pelo Coolify

#### Scenario: Senha operacional existente
- **WHEN** já existe senha persistida para o usuário monitor no diretório operacional do collector
- **THEN** o sistema reutiliza essa senha para reconciliar o usuário no PostgreSQL por meio do container gerenciado pelo Coolify e configurar o collector

#### Scenario: Sincronização entre .env e PostgreSQL
- **WHEN** o `.env` operacional privado contém a senha do usuário monitor
- **THEN** essa senha é a fonte usada pelo script remoto para executar `CREATE ROLE` ou `ALTER ROLE` no PostgreSQL da aplicação a partir do container gerenciado pelo Coolify

#### Scenario: Container PostgreSQL não encontrado
- **WHEN** o script remoto não consegue identificar ou acessar o container PostgreSQL da aplicação gerenciado pelo Coolify
- **THEN** a instalação do collector falha com uma mensagem clara antes de alterar credenciais ou subir o container do collector

### Requirement: Permissões mínimas para coleta do PostgreSQL
O sistema SHALL conceder somente permissões necessárias para a coleta inicial de métricas do PostgreSQL.

#### Scenario: Coleta básica habilitada
- **WHEN** o usuário monitor é criado ou verificado
- **THEN** ele recebe permissão para conectar ao banco alvo e ler estatísticas necessárias para métricas básicas do receiver PostgreSQL

#### Scenario: Coleta avançada fora do escopo inicial
- **WHEN** query samples, top queries, planos de query ou métricas dependentes de extensões adicionais forem desejadas
- **THEN** o sistema exige uma mudança posterior com permissões, extensões e riscos de exposição documentados explicitamente

### Requirement: Deploy separado do collector
O sistema SHALL executar o collector como uma unidade de deploy separada do Coolify e da stack principal do SigNoz.

#### Scenario: Collector instalado
- **WHEN** o operador executa a task de instalação do collector
- **THEN** o sistema provisiona uma stack Docker Compose própria para o collector em diretório operacional dedicado na VPS

#### Scenario: Ciclo de vida independente
- **WHEN** a aplicação Espresso, o PostgreSQL ou o SigNoz forem reiniciados ou atualizados por seus próprios fluxos
- **THEN** o collector permanece gerenciado por seu fluxo de observabilidade separado e não altera o ciclo de vida desses componentes

#### Scenario: Reexecução do deploy
- **WHEN** a instalação do collector é executada novamente
- **THEN** o sistema reaplica ou verifica a configuração de forma idempotente, sem apagar credenciais, volumes ou estado operacional existente

### Requirement: Conectividade entre Coolify e SigNoz
O sistema SHALL conectar o collector às redes Docker necessárias para ler o PostgreSQL da aplicação e exportar métricas ao SigNoz.

#### Scenario: Redes Docker disponíveis
- **WHEN** as redes Docker do Coolify e do SigNoz existem na VPS
- **THEN** o collector é conectado às duas redes para acessar o PostgreSQL pela rede do Coolify e o `signoz-ingester` pela rede do SigNoz

#### Scenario: Rede Docker ausente
- **WHEN** a rede do Coolify ou a rede do SigNoz não existe
- **THEN** a instalação do collector falha com uma mensagem clara indicando a dependência ausente

#### Scenario: Postgres não publicado no host
- **WHEN** o PostgreSQL da aplicação não expõe a porta `5432` no host da VPS
- **THEN** o collector ainda consegue acessar o banco pela rede Docker do Coolify usando o host configurado ou detectado

### Requirement: Exportação de métricas para o SigNoz
O sistema SHALL enviar as métricas coletadas do PostgreSQL ao SigNoz usando OTLP.

#### Scenario: SigNoz disponível
- **WHEN** o `signoz-ingester` está acessível na rede Docker do SigNoz
- **THEN** o collector exporta métricas do PostgreSQL para o endpoint OTLP interno documentado

#### Scenario: SigNoz indisponível
- **WHEN** o `signoz-ingester` não está acessível
- **THEN** o status do collector indica falha de exportação sem expor credenciais sensíveis nos logs ou na saída da task

### Requirement: Status operacional do collector
O sistema SHALL expor uma verificação operacional para o collector do PostgreSQL.

#### Scenario: Status consultado
- **WHEN** um operador executa a task de status de observabilidade
- **THEN** a saída informa se o collector está instalado, se o container está em execução, se as redes esperadas estão conectadas e se há sinais recentes de erro nos logs

#### Scenario: Credenciais protegidas em status
- **WHEN** o status do collector é exibido
- **THEN** nenhuma senha, token, string de conexão completa ou segredo equivalente é impresso

### Requirement: Documentação do fluxo Postgres Collector
O sistema SHALL atualizar a documentação do repositório para explicar o collector do PostgreSQL, seus limites operacionais e sua relação com Coolify e SigNoz.

#### Scenario: Documentação principal atualizada
- **WHEN** a mudança é implementada
- **THEN** `README.md` e `architecture.md` documentam a existência do collector, suas tasks, variáveis, credenciais locais na VPS, redes Docker envolvidas e limites de escopo

#### Scenario: Documento dedicado criado
- **WHEN** a mudança é implementada
- **THEN** o arquivo `postgres_collector_archtecture.md` é criado ao lado de `architecture.md` para explicar somente o fluxo PostgreSQL -> collector -> SigNoz

#### Scenario: Documento dedicado lido pelo operador
- **WHEN** um operador lê `postgres_collector_archtecture.md`
- **THEN** ele encontra a topologia do collector, o fluxo de criação e aplicação da senha, o caminho de deploy, a separação em relação ao Coolify, a separação em relação ao collector interno do SigNoz e os procedimentos básicos de validação

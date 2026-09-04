# infra-documentation Specification

## Purpose

Define o contrato de organizacao e conteudo minimo da documentacao do Espresso Infra, para que operadores encontrem rapidamente a visao geral, os detalhes de Coolify, SigNoz, collector PostgreSQL e a fronteira com o repositorio externo da aplicacao Espresso API.

## Requirements

### Requirement: README como entrada geral
O sistema SHALL manter o `README.md` como ponto de entrada geral da documentacao do Espresso Infra, priorizando visao do projeto, quickstart e links para documentos detalhados.

#### Scenario: Operador le o README
- **WHEN** um operador abre o `README.md`
- **THEN** o documento apresenta a finalidade do repositorio, o que a infraestrutura provisiona, o que fica fora de escopo, os pre-requisitos principais e um sumario com links para a documentacao detalhada

#### Scenario: Detalhes operacionais movidos para docs dedicados
- **WHEN** o README menciona Coolify, SigNoz, collector PostgreSQL, tasks, portas ou variaveis
- **THEN** ele resume o assunto e aponta para o documento dedicado em vez de duplicar a explicacao operacional completa

### Requirement: Documentacao detalhada por area
O sistema SHALL organizar os detalhes de infraestrutura em arquivos Markdown dedicados por area funcional.

#### Scenario: Documentos dedicados existem
- **WHEN** a documentacao detalhada for consultada
- **THEN** existem documentos dedicados para arquitetura, aplicacao Espresso API, Coolify, SigNoz, collector PostgreSQL e operacao recorrente

#### Scenario: Assunto pertence a uma area
- **WHEN** um detalhe operacional pertence primariamente a Coolify, SigNoz, collector PostgreSQL, aplicacao ou operacao geral
- **THEN** esse detalhe fica no documento dedicado da area correspondente

### Requirement: Documentacao minima da aplicacao externa
O sistema SHALL documentar a relacao operacional entre este repositorio de infraestrutura e o repositorio externo da aplicacao Espresso API.

#### Scenario: Operador procura o codigo da aplicacao
- **WHEN** um operador consulta a documentacao da aplicacao
- **THEN** ela referencia `https://github.com/evellyncosta/espresso-api` como repositorio externo da aplicacao

#### Scenario: Fronteira entre aplicacao e infraestrutura
- **WHEN** um operador consulta a documentacao da aplicacao
- **THEN** ela diferencia responsabilidades da aplicacao, do Coolify e deste repositorio de infraestrutura

#### Scenario: Dependencias runtime da aplicacao
- **WHEN** um operador consulta a documentacao da aplicacao
- **THEN** ela descreve em nivel minimo as dependencias esperadas de runtime, incluindo PostgreSQL, Redis/Valkey e endpoints de observabilidade SigNoz/OTLP, sem expor secrets reais

### Requirement: Documentacao dedicada de Coolify
O sistema SHALL documentar Coolify em um Markdown dedicado com foco em responsabilidades, acesso e relacao com os servicos da aplicacao.

#### Scenario: Operador consulta Coolify
- **WHEN** um operador abre a documentacao dedicada de Coolify
- **THEN** ela explica acesso inicial, portas diretas relevantes, responsabilidades do Coolify e quais componentes da aplicacao ele gerencia

### Requirement: Documentacao dedicada de SigNoz
O sistema SHALL documentar SigNoz em um Markdown dedicado com foco em instalacao, operacao e limites da observabilidade.

#### Scenario: Operador consulta SigNoz
- **WHEN** um operador abre a documentacao dedicada de SigNoz
- **THEN** ela explica Foundry/foundryctl, diretorio padrao, requisito minimo de memoria, portas publicas, endpoints OTLP, firewall e limites fora de escopo deste repositorio

### Requirement: Links internos validos
O sistema SHALL manter links internos da documentacao consistentes apos a reorganizacao dos arquivos Markdown.

#### Scenario: Navegacao entre documentos
- **WHEN** um operador usa os links do README ou dos documentos em `docs/`
- **THEN** os links apontam para arquivos existentes e nao dependem dos nomes antigos movidos ou renomeados

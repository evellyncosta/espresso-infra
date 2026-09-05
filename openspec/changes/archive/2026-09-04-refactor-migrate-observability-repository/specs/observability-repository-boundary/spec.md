## Purpose

Define a fronteira operacional entre o Espresso Infra e o repositório externo de observabilidade, para que SigNoz e o collector PostgreSQL tenham lifecycle independente da infraestrutura base.

## ADDED Requirements

### Requirement: Lifecycle de observabilidade externo ao Espresso Infra
O Espresso Infra SHALL não disponibilizar tasks, scripts, variáveis de ambiente ou fluxos que instalem, consultem o status, alterem firewall ou destruam SigNoz, Foundry/foundryctl ou o collector PostgreSQL.

#### Scenario: Operador lista as tasks do infra
- **WHEN** um operador executa a listagem de tasks públicas do Espresso Infra
- **THEN** a listagem não oferece comandos de lifecycle de observabilidade

#### Scenario: Operador procura a configuração local do infra
- **WHEN** um operador consulta o arquivo de exemplo de ambiente do Espresso Infra
- **THEN** o arquivo não contém variáveis específicas de SigNoz, Foundry/foundryctl ou collector PostgreSQL

### Requirement: Referência ao repositório de observabilidade
O Espresso Infra SHALL referenciar `https://github.com/evellyncosta/espresso-observability` como fonte de verdade para tasks, scripts, variáveis, documentação e lifecycle da observabilidade.

#### Scenario: Operador procura a operação de observabilidade
- **WHEN** um operador consulta o README ou a documentação operacional do Espresso Infra
- **THEN** encontra uma referência navegável ao repositório externo de observabilidade em vez de instruções locais de instalação ou destruição

### Requirement: Contrato de integração preservado
O Espresso Infra SHALL documentar somente os pré-requisitos de integração que disponibiliza à observabilidade: acesso SSH à VPS, Docker e Compose prontos, e, quando o collector PostgreSQL for usado, Coolify, PostgreSQL da aplicação e a rede Docker correspondente já existentes.

#### Scenario: Repositório de observabilidade é executado após o bootstrap
- **WHEN** o operador executa o fluxo de observabilidade numa VPS preparada pelo Espresso Infra
- **THEN** a documentação deixa claro quais componentes pertencem ao infra e quais são pré-requisitos externos ao repositório de observabilidade

#### Scenario: Observabilidade é removida
- **WHEN** a plataforma de observabilidade é destruída por seu repositório próprio
- **THEN** Coolify, Docker base, PostgreSQL da aplicação e dados da aplicação permanecem fora do escopo dessa operação conforme o contrato documentado

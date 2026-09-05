## MODIFIED Requirements

### Requirement: README como entrada geral
O sistema SHALL manter o `README.md` como ponto de entrada geral da documentacao do Espresso Infra, priorizando visao do projeto, quickstart e links para documentos detalhados.

#### Scenario: Operador abre o README
- **WHEN** um operador abre o `README.md`
- **THEN** o documento apresenta a finalidade do repositorio, o que a infraestrutura provisiona, o que fica fora de escopo, os pre-requisitos principais e um sumario com links para a documentacao detalhada

#### Scenario: Detalhes operacionais movidos para docs dedicados
- **WHEN** o README menciona Coolify, tarefas, portas, variaveis ou observabilidade
- **THEN** ele resume o assunto e aponta para o documento dedicado da area correspondente ou para o repositorio externo de observabilidade, sem duplicar explicacoes operacionais completas

### Requirement: Documentacao detalhada por area
O sistema SHALL organizar os detalhes de infraestrutura que possui em arquivos Markdown dedicados por area funcional e referenciar repositorios externos para areas que nao possui.

#### Scenario: Documentos dedicados existem
- **WHEN** a documentacao detalhada for consultada
- **THEN** existem documentos dedicados para arquitetura, aplicacao Espresso API, Coolify e operacao recorrente, e uma referencia ao repositorio externo de observabilidade

#### Scenario: Assunto pertence a uma area
- **WHEN** um detalhe operacional pertence primariamente a Coolify, aplicacao ou operacao geral
- **THEN** esse detalhe fica no documento dedicado da area correspondente

#### Scenario: Assunto pertence a observabilidade
- **WHEN** um operador procura instrucoes de SigNoz ou collector PostgreSQL
- **THEN** a documentacao do infra referencia o repositorio externo de observabilidade em vez de manter instrucoes locais

## REMOVED Requirements

### Requirement: Documentacao dedicada de SigNoz
**Reason**: SigNoz e o collector PostgreSQL passam a ser operados e documentados no repositório externo de observabilidade.

**Migration**: Consultar `https://github.com/evellyncosta/espresso-observability` para instalação, operação, status, destruição e documentação de observabilidade.

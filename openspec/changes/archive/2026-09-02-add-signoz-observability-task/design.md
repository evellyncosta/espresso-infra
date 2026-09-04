## Contexto

Veja `proposal.md` para a motivação. O repositório atualmente provisiona a base da VPS com Taskfile, scripts SSH, Docker, UFW e Coolify. A migração anterior deixou observabilidade, OpenTelemetry e SigNoz explicitamente fora de escopo; esta change passa a incluir SigNoz como infraestrutura provisionada por este repositório.

O caminho atual de instalação do SigNoz em Docker usa Foundry/foundryctl. O `install.sh` legado do SigNoz e os arquivos Compose antigos em `deploy/` foram depreciados em favor do Foundry. O Foundry usa um `casting.yaml` declarativo, valida pré-requisitos, gera arquivos de deploy e aplica a stack.

Referências:

- Guia de instalação Docker do SigNoz: https://signoz.io/docs/install/docker/
- Guia inicial do Foundry: https://github.com/SigNoz/foundry/blob/main/docs/getting-started.md
- Referência da CLI Foundry: https://github.com/SigNoz/foundry/blob/main/docs/reference/cli.md

## Objetivos / Fora de Escopo

**Objetivos:**

- Adicionar pontos de entrada no Taskfile para instalar/verificar `foundryctl` e SigNoz.
- Manter a execução remota pelo padrão SSH já existente.
- Instalar SigNoz pelo Foundry com Docker Compose, sem usar caminhos de instalação depreciados.
- Manter a instalação idempotente para execuções repetidas.
- Documentar como a aplicação Spring pode enviar telemetria para o SigNoz.
- Manter SigNoz operacionalmente separado da stack da aplicação gerenciada pelo Coolify.

**Fora de escopo:**

- Instrumentar a aplicação Spring neste repositório.
- Configurar dashboards, alertas, política de retenção ou API keys de conta de serviço.
- Habilitar SigNoz MCP na primeira versão, porque sua porta padrão `8000` conflita com a porta direta do dashboard do Coolify.
- Migrar dados de uma instalação SigNoz existente anterior ao Foundry.
- Mover aplicação, PostgreSQL ou Redis/Valkey para fora do Coolify.

## Decisões

### Usar Foundry/foundryctl como caminho de instalação do SigNoz

A implementação deve instalar `foundryctl` usando o instalador suportado do Foundry ou uma versão pinada quando configurada, e então usar `foundryctl cast -f casting.yaml` para fazer deploy do SigNoz.

Racional: isso segue o caminho atualmente suportado pelo SigNoz para Docker Compose. Chamar scripts antigos de instalação do SigNoz ou venderizar arquivos Compose acoplaria este repositório a artefatos depreciados.

Alternativa considerada: fazer deploy do SigNoz pelo Coolify. O Foundry tem um exemplo para Coolify, mas a primeira versão deve preferir Docker Compose fora do Coolify porque este repositório já é responsável pelo provisionamento no nível do host, e manter observabilidade separada evita aninhar o ciclo de vida de uma plataforma dentro da outra.

### Adicionar observabilidade como módulo separado do Taskfile

Adicionar um módulo como `tasks/observability.yml` com tasks públicas:

- `install:foundryctl`
- `install:signoz`
- `observability:status`

O fluxo raiz `setup` pode incluir SigNoz diretamente ou expor uma segunda task agregada como `setup:observability`. O padrão mais seguro é manter SigNoz opt-in até que memória, portas e exposição desejada estejam confirmadas para a VPS.

Racional: SigNoz é mais pesado que o bootstrap base da VPS e pode falhar por motivos não relacionados ao Coolify. Um módulo separado reduz o raio de impacto e ainda mantém observabilidade provisionável por este repositório.

### Armazenar estado do SigNoz em um diretório dedicado no host

Usar um diretório configurável como `/data/signoz` para `casting.yaml`, saída gerada pelo Foundry e estado operacional que deve sobreviver a reexecuções.

Racional: `/data/coolify` pertence ao Coolify. Manter SigNoz em um diretório irmão deixa a propriedade clara e simplifica checagens de status, backup e remoção futura.

### Desabilitar SigNoz MCP por padrão

O servidor MCP do SigNoz é útil, mas a porta padrão documentada é `8000`, que já é usada pelo acesso direto ao dashboard do Coolify neste projeto. A primeira versão não deve habilitar MCP.

Racional: instalar observabilidade não deve quebrar o acesso ao Coolify nem exigir remapeamento de portas. MCP pode ser uma change posterior com mapeamento de porta, autenticação e documentação explícitos.

### Tratar exposição OTLP como infraestrutura intencional

O SigNoz normalmente expõe:

- `8081/tcp` para a UI do SigNoz na VPS, mapeando para `8080/tcp` no container gerado pelo Foundry.
- `4317/tcp` para OTLP gRPC.
- `4318/tcp` para OTLP HTTP.

A task de firewall deve tornar essa exposição explícita e documentada. A porta `8081` evita conflito com outro serviço local que já usa `8080`. Se a implementação suportar desabilitar OTLP público, deve usar como padrão a política mais restrita que ainda permita à aplicação Spring exportar telemetria a partir da topologia de deploy escolhida.

Racional: endpoints OTLP podem receber dados operacionais. Expor essas portas publicamente é conveniente, mas deve ser uma decisão consciente de infraestrutura, não um efeito colateral acidental.

## Riscos / Compromissos

- SigNoz pode exceder a memória disponível da VPS -> Documentar o requisito de 4GB de memória para Docker e falhar com aviso acionável quando o host estiver claramente subdimensionado.
- Conflitos de porta com Coolify ou containers da aplicação -> Verificar portas necessárias antes da primeira instalação e falhar antes de alterar estado do SigNoz.
- Endpoints OTLP públicos podem receber telemetria de clientes indesejados -> Documentar a exposição e permitir endurecimento futuro por política de firewall ou proxy.
- Saída gerada pelo Foundry pode ser sobrescrita em reexecuções -> Tratar `casting.yaml` como fonte da verdade e evitar edições manuais nos arquivos gerados em `pours/`.
- Ciclo de vida separado do Coolify cria duas superfícies operacionais -> Manter tasks e checagens de status claras para que operadores saibam quando investigar Coolify ou Foundry/SigNoz.

## Plano de Migração

1. Adicionar opções no `.env.example` para Foundry/foundryctl, diretório do SigNoz e exposição no firewall.
2. Adicionar scripts remotos para instalação do `foundryctl`, instalação do SigNoz e status de observabilidade.
3. Adicionar um módulo Taskfile e aliases raiz para as novas tasks.
4. Atualizar a lógica de UFW para considerar portas do SigNoz quando observabilidade estiver habilitada.
5. Atualizar README e documentação de arquitetura com SigNoz, endpoints OTLP e propriedade operacional.
6. Validar sintaxe dos scripts e listagem do Taskfile localmente.

Reversão das mudanças do repositório é um revert Git normal antes do uso em produção. Reversão de uma VPS onde SigNoz foi instalado é manual: parar a stack Compose gerada, inspecionar `/data/signoz` e preservar ou remover Docker volumes deliberadamente conforme a telemetria deva ser retida ou descartada.

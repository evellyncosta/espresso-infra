## Por que

O projeto agora precisa provisionar observabilidade self-hosted junto da infraestrutura da aplicação Espresso. SigNoz cobre métricas, traces e logs em uma VPS Docker, e o caminho atual suportado para instalação é via Foundry/foundryctl.

## O que muda

- Adicionar uma task para instalar ou verificar o `foundryctl` na VPS.
- Adicionar uma task para instalar ou verificar o SigNoz self-hosted usando Foundry com `flavor: compose` e `mode: docker`.
- Integrar as novas tasks ao Taskfile mantendo o fluxo idempotente e executado por SSH.
- Adicionar checagens de status para `foundryctl` e containers/endpoint do SigNoz.
- Documentar variáveis opcionais, portas, requisitos de memória e relação entre SigNoz, Coolify, aplicação Spring, PostgreSQL e Redis/Valkey.
- Atualizar o firewall para permitir as portas necessárias do SigNoz quando observabilidade estiver habilitada.
- Manter SigNoz fora do ciclo de vida da aplicação gerenciada pelo Coolify, usando Foundry/foundryctl como instalador e gerenciador da stack de observabilidade.

## Capacidades

### Novas capacidades

- `signoz-observability`: Provisionamento de observabilidade self-hosted na VPS com Foundry/foundryctl e SigNoz, incluindo instalação, idempotência, firewall, status e documentação operacional.

### Capacidades modificadas

- Nenhuma.

## Impacto

- `Taskfile.yml` e arquivos em `tasks/` deverão expor tasks públicas para Foundry/foundryctl e SigNoz.
- `scripts/` deverá ganhar scripts remotos focados para instalação e status da observabilidade.
- `.env.example` deverá incluir variáveis opcionais para instalação do Foundry/foundryctl, diretório do SigNoz e habilitação de portas/recursos opcionais.
- `README.md` e `architecture.md` deverão refletir SigNoz como parte da infraestrutura provisionada e mostrar sua relação com a aplicação Spring e serviços gerenciados pelo Coolify.
- Regras de firewall deverão considerar as portas HTTP do SigNoz e OTLP, evitando conflito com portas já usadas pelo Coolify.

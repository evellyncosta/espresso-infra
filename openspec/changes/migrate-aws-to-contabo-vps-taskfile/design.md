## Contexto

Veja `proposal.md` para a motivação. O repositório atual é um projeto pequeno de infraestrutura AWS em Pulumi/Python, com recursos de runtime para RDS, ElastiCache/Valkey, ECR, ECS Express Mode, CloudWatch, IAM, rede VPC e Client VPN. Não há specs principais existentes no OpenSpec, então esta change introduz a nova capability `contabo-vps-bootstrap`.

O servidor alvo já será criado fora deste repositório. A implementação deve tratá-lo como um alvo SSH e não deve chamar APIs da Contabo nem introduzir outro sistema de provisionamento. A documentação atual de instalação self-hosted do Coolify dá suporte a servidores Debian-based e recomenda Ubuntu LTS quando Ubuntu for usado; o bootstrap deve inicialmente mirar Debian 12 e Ubuntu 22.04/24.04 LTS, salvo se a implementação identificar um caminho mais amplo já suportado.

## Objetivos / Fora de Escopo

**Objetivos:**

- Fornecer um ponto de entrada previsível via Taskfile para desenvolvedores executarem bootstrap de uma VPS nova.
- Manter tasks componíveis para que `task setup` orquestre tasks menores de sistema, segurança, Docker e Coolify.
- Fazer a execução remota depender de variáveis em `.env`, sem secrets commitados.
- Preservar acesso SSH durante mudanças de firewall e documentar todas as portas públicas.
- Deixar o deploy da aplicação e o ciclo de vida de serviços sob responsabilidade do Coolify após o bootstrap.
- Remover infraestrutura de runtime exclusiva da AWS do caminho operacional.

**Fora de escopo:**

- Provisionar, excluir, redimensionar ou gerenciar de qualquer outra forma a VPS Contabo.
- Criar ou anexar volumes externos da Contabo.
- Substituir fluxos do Coolify para deploy, variáveis de ambiente, domínio, restart ou gerenciamento de serviços.
- Migrar dados de produção automaticamente.
- Implementar CI/CD, observabilidade, migração de logs históricos ou automação completa de backup.
- Remover integrações AWS funcionais que continuem sendo dependências da aplicação fora da hospedagem.

## Decisions

### Usar Taskfile como única interface operacional pública

Criar um `Taskfile.yml` na raiz que carrega arquivos modulares de tasks em `tasks/`. As tasks públicas devem incluir no mínimo `setup`, `bootstrap` ou alias equivalente, `system`, `security`, `install:docker`, `install:coolify` e helpers simples de validação/listagem se forem úteis.

Racional: isso dá ao desenvolvedor uma única interface local e mantém cada preocupação legível. As alternativas consideradas foram um script shell único e Makefile. Um script único seria mais difícil de inspecionar e reexecutar por etapa; Makefile funcionaria, mas a interface solicitada é Taskfile.

### Executar mudanças no servidor por SSH e scripts pequenos

As tasks do Taskfile devem validar o ambiente local e então executar scripts shell focados remotamente via SSH. Os scripts devem ficar em `scripts/` e ser separados por preocupação, por exemplo `system.sh`, `security.sh`, `docker.sh` e `coolify.sh`.

Racional: Taskfile permanece como orquestração, enquanto scripts tratam verificações de sistema operacional com `set -euo pipefail`, logs claros e proteções reutilizáveis. Ansible ou Terraform seriam sistemas de provisionamento mais amplos e estão explicitamente fora de escopo.

### Mirar primeiro distribuições Linux suportadas de forma conservadora

Implementar detecção explícita de sistema operacional e dar suporte primeiro a Debian 12 e Ubuntu 22.04/24.04 LTS. Sistemas não suportados devem falhar antes de mudanças materiais.

Racional: a documentação self-hosted do Coolify descreve suporte a Debian/Ubuntu e destaca Ubuntu LTS para o instalador automático. Isso evita bootstrap parcial em distribuições não LTS ou desconhecidas.

### Instalar Docker de forma idempotente antes do Coolify

A task de Docker deve verificar se Docker Engine e o plugin Compose funcionam antes de instalar. Se Docker já existir, deve verificar o estado do serviço e habilitar inicialização automática. Se Docker estiver ausente, deve instalar Docker pelo caminho oficial de pacotes adequado ao sistema detectado, evitando Docker via snap.

Racional: Coolify depende de Docker, e a documentação de troubleshooting aponta explicitamente Docker via snap como não suportado. Deixar o instalador do Coolify instalar Docker é possível, mas uma task dedicada de Docker fornece logs mais claros e uma verificação melhor para `docker --version` e status do serviço.

### Instalar Coolify pelo instalador suportado

A task do Coolify deve usar o caminho atual suportado do script de instalação self-hosted, executar com privilégios de root ou sudo e verificar os containers resultantes ou o caminho de acesso ao dashboard. Ela não deve hardcodar secrets gerados pelo Coolify nem reescrever valores existentes em `/data/coolify/source/.env` em reexecuções.

Racional: Coolify é responsável pelos seus arquivos compose internos, secrets e caminho de upgrade. Compor manualmente esses detalhes neste repositório duplicaria internals do Coolify e aumentaria risco em upgrades.

### Manter regras de firewall explícitas e seguras para SSH

A task de segurança deve usar `ufw` em sistemas Debian/Ubuntu suportados, salvo se a implementação encontrar um padrão local existente melhor. Ela deve liberar a porta SSH configurada antes de habilitar ou recarregar o firewall. As portas TCP públicas necessárias para o servidor Coolify self-hosted são:

- `22` ou porta SSH configurada para acesso SSH
- `80` e `443` para HTTP/HTTPS e tráfego de certificados/proxy
- `8000` para acesso direto inicial ao dashboard do Coolify
- `6001` para atualizações em tempo real do dashboard quando acessado por IP direto
- `6002` para terminal web por IP direto

A documentação deve informar que `8000`, `6001` e `6002` podem ser restringidas ou fechadas depois que o dashboard estiver roteado por domínio/proxy, se o operador escolher esse caminho.

### Tratar persistência como armazenamento local gerenciado pelo Docker

O bootstrap não deve criar volumes do provedor. Serviços gerenciados pelo Coolify devem usar Docker volumes ou bind mounts explícitos no filesystem da VPS. A documentação deve destacar que PostgreSQL, Redis/Valkey e dados da aplicação não devem viver apenas nas camadas graváveis dos containers.

Racional: isso corresponde ao modelo de VPS e à restrição de não usar volume externo. Backups permanecem uma task futura, então esta change deve documentar o limite de persistência sem prometer automação de backup.

### Remover infraestrutura AWS de runtime deliberadamente

Durante a implementação, substituir o caminho operacional AWS/Pulumi pelo caminho Taskfile/Coolify. Recursos AWS usados apenas pela hospedagem antiga podem ser removidos do repositório ativo, incluindo ECS Express Mode, ECR, CloudWatch log groups, IAM task roles, VPC endpoints, security groups, helpers de Client VPN, RDS e provisionamento de ElastiCache/Valkey quando esses serviços passarem para o Coolify.

Racional: o host de runtime muda para a VPS. A implementação ainda deve inspecionar se algum serviço AWS é dependência funcional da aplicação antes de excluir configurações relacionadas.

## Riscos / Trade-offs

- Bloqueio de SSH durante configuração do firewall -> Liberar e verificar SSH antes de habilitar/recarregar o firewall; falhar cedo quando a porta SSH for desconhecida.
- Mudanças upstream no instalador do Coolify -> Manter o comando de instalação e a documentação vinculados à documentação oficial do Coolify; não venderizar nem criar fork do instalador.
- Servidor existente não é novo -> Executar preflights para Docker existente, portas ocupadas, caminho existente do Coolify e sistema operacional não suportado; falhar com logs acionáveis quando conflitos forem inseguros.
- VPS única reduz a resiliência de serviços gerenciados -> Documentar que backups, testes de restore e migração de dados de produção são trabalhos futuros e não são resolvidos por este bootstrap.
- Remover código AWS pode apagar integrações externas ainda necessárias -> Separar dependências de hospedagem/runtime de dependências funcionais da aplicação durante a implementação.
- Executar builds, banco e aplicação em uma única VPS pode esgotar recursos -> Deixar sizing como responsabilidade do operador e documentar que CPU, memória e disco devem ser monitorados fora desta change.

## Plano de Migração

1. Adicionar estrutura de Taskfile, `.env.example`, scripts focados e documentação para o bootstrap Contabo.
2. Implementar validação local de preflight para variáveis obrigatórias, alcance SSH e detecção de sistema operacional suportado.
3. Implementar tasks remotas idempotentes para preparação do sistema, firewall, Docker e Coolify.
4. Substituir o conteúdo do README pelo fluxo operacional VPS/Coolify e documentar responsabilidades das tasks.
5. Remover ou isolar arquivos e scripts AWS/Pulumi de runtime exclusivos do caminho antigo de hospedagem.
6. Validar `task --list` localmente e executar checagens de sintaxe para Taskfile e scripts shell.
7. Quando uma VPS descartável compatível estiver disponível, executar `task setup` duas vezes para validar primeiro uso e idempotência.
8. Após o bootstrap, configurar aplicação, serviços PostgreSQL/Redis, domínios e variáveis de ambiente dentro do Coolify.

Rollback de mudanças de planejamento/implementação é revert no repositório antes de uso em produção. Depois que uma VPS for preparada, rollback do estado do servidor é manual: parar containers do Coolify se necessário, revisar `/data/coolify`, pacotes Docker, regras de firewall e volumes antes de remover qualquer coisa. O bootstrap não deve incluir tasks destrutivas de limpeza por padrão.

## Perguntas em Aberto

- A imagem exata de sistema operacional da VPS Contabo de produção pode ser confirmada durante implementação/testes, mas o design já assume Debian 12 ou Ubuntu 22.04/24.04 LTS como conjunto inicial suportado.

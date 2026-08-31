## 1. Estrutura de Bootstrap do Repositório

- [x] 1.1 Adicionar `Taskfile.yml` na raiz com carregamento de dotenv, includes modulares, descrições das tasks públicas, e verificar que `task --list` mostra as tasks de bootstrap.
- [x] 1.2 Adicionar arquivos modulares de tasks em `tasks/` para etapas de sistema, segurança, Docker e Coolify, e verificar que `task --list` inclui cada task pública com descrição clara.
- [x] 1.3 Adicionar `.env.example` com variáveis não sensíveis para `SERVER_HOST`, `SERVER_USER`, `SSH_KEY_PATH`, porta SSH, timezone e configurações opcionais do Coolify, e verificar que nenhum valor real de secret está presente.
- [x] 1.4 Garantir que `.env` seja ignorado pelo controle de versão, e verificar que `git check-ignore .env` retorna sucesso.

## 2. Base de Execução Remota

- [x] 2.1 Implementar validação local de ambiente usada pelas tasks remotas, e verificar que executar uma task remota sem `SERVER_HOST`, `SERVER_USER` ou `SSH_KEY_PATH` falha antes da execução SSH com o nome da variável ausente.
- [x] 2.2 Implementar um padrão reutilizável de comando SSH para tasks do Taskfile, e verificar que uma task seca de validação consegue executar `whoami` ou comando inofensivo equivalente no servidor configurado.
- [x] 2.3 Adicionar convenções para scripts shell focados com `set -euo pipefail`, logs por etapa e comportamento compartilhado de falha, e verificar que cada script passa em `bash -n`.
- [x] 2.4 Implementar detecção de sistema operacional suportado para Debian 12 e Ubuntu 22.04/24.04 LTS, e verificar que a detecção de sistema não suportado sai antes da lógica de instalação do Docker ou Coolify.

## 3. Tasks de Preparação da VPS

- [x] 3.1 Implementar o script de preparação do sistema para atualização de pacotes, dependências básicas e configuração opcional de timezone, e verificar que reexecutá-lo não duplica configuração nem falha em pacotes já instalados.
- [x] 3.2 Implementar configuração de firewall segura para SSH com regras para SSH, HTTP, HTTPS, `8000/tcp`, `6001/tcp` e `6002/tcp`, e verificar que a regra SSH é aplicada antes de habilitar ou recarregar o firewall.
- [x] 3.3 Documentar quando as portas diretas do Coolify `8000`, `6001` e `6002` podem ser restringidas após roteamento por domínio/proxy, e verificar que o README lista cada porta aberta e seu motivo.
- [x] 3.4 Implementar instalação do Docker e habilitação do serviço, evitando Docker via snap, e verificar que `docker --version`, `docker compose version` e `systemctl is-active docker` remotos retornam sucesso.
- [x] 3.5 Tornar a task de Docker idempotente para instalações existentes, e verificar que uma segunda execução preserva a instalação existente do Docker e termina com sucesso.

## 4. Bootstrap do Coolify

- [x] 4.1 Implementar instalação do Coolify usando o caminho suportado do instalador self-hosted, e verificar que a task cria ou preserva `/data/coolify/source` sem hardcodar secrets gerados.
- [x] 4.2 Adicionar preflights do Coolify para prontidão do Docker, portas necessárias e estado de instalação existente, e verificar que conflitos inseguros falham com logs acionáveis.
- [x] 4.3 Adicionar verificação operacional do Coolify após a instalação, e verificar que checagens remotas confirmam os containers esperados do Coolify ou caminho de acesso ao dashboard.
- [x] 4.4 Garantir que reexecutar a task do Coolify preserva secrets e configurações existentes, e verificar que uma segunda execução não reescreve `/data/coolify/source/.env` inesperadamente.

## 5. Remoção do Runtime AWS e Documentação

- [x] 5.1 Inventariar arquivos e scripts de runtime AWS/Pulumi, e verificar que cada referência a ECS, ECR, CloudWatch, IAM, security group, VPC endpoint, RDS, ElastiCache/Valkey e Client VPN está classificada como hospedagem antiga de runtime ou dependência externa funcional.
- [x] 5.2 Remover ou isolar arquivos e dependências usados exclusivamente pelo caminho antigo de runtime AWS, e verificar que nenhum comando ativo de bootstrap depende de Pulumi, Terraform, OpenTofu ou Ansible.
- [x] 5.3 Preservar e documentar qualquer integração AWS que permaneça como dependência funcional da aplicação, e verificar que a documentação a diferencia da infraestrutura de hospedagem de runtime.
- [x] 5.4 Reescrever a documentação do repositório com pré-requisitos, configuração, bootstrap, tasks públicas, limites de responsabilidade do Coolify, persistência e itens fora de escopo, e verificar que um desenvolvedor consegue seguir o fluxo documentado `cp .env.example .env` e depois `task setup`.

## 6. Validação

- [x] 6.1 Executar validação estática local do Taskfile e dos scripts shell, e verificar que `task --list` e `bash -n scripts/*.sh` retornam sucesso.
- [x] 6.2 Verificar higiene de secrets no repositório, e confirmar que nenhuma chave privada, token, senha ou credencial real de servidor foi adicionada a arquivos rastreados.
- [x] 6.3 Em uma VPS descartável compatível, executar `task setup` uma vez e verificar que Docker está ativo, Coolify está operacional e as portas documentadas estão acessíveis conforme esperado.
- [x] 6.4 Na mesma VPS descartável, executar `task setup` uma segunda vez e verificar idempotência: sem configuração duplicada, sem perda de dados e sem falha causada apenas por estado existente de Docker, firewall ou Coolify.
- [x] 6.5 Verificar separação entre bootstrap e deploy confirmando que o caminho normal de deploy da aplicação está documentado como repositório Git para Coolify para VPS Contabo sem reexecutar o bootstrap completo.

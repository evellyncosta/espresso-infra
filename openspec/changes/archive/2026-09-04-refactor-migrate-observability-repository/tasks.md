## 1. Base independente de observabilidade

- [x] 1.1 Criar no `espresso-observability` a estrutura operacional mínima (`README.md`, `Taskfile.yml`, `.env.example`, `tasks/`, `scripts/` e `docs/`) sem criar `openspec/specs/` ou `docs/adrs/`, e verificar que o repositório continua sem specs e ADRs.
- [x] 1.2 Implementar no novo repositório um executor SSH próprio e validação de ambiente para as variáveis de observabilidade, e verificar que ele executa um preflight sem depender de arquivos ou caminhos do `espresso-infra`.
- [x] 1.3 Documentar no novo repositório o contrato de integração com VPS, Docker/Compose, Coolify, PostgreSQL e redes Docker existentes, e verificar que a documentação atribui cada responsabilidade ao repositório correto.

## 2. Lifecycle de destruição

- [x] 2.1 Implementar a task pública `destroy` no `espresso-observability` para identificar e remover somente containers, redes, volumes, diretórios e estado de SigNoz/Foundry e do collector PostgreSQL, e verificar que uma segunda execução com a instalação ausente termina de forma segura.
- [x] 2.2 Implementar remoção das regras UFW específicas de SigNoz com identificação restrita e confirmação/falha para regras ambíguas, e verificar que regras de SSH, HTTP, HTTPS e Coolify não são alteradas.
- [x] 2.3 Definir a política explícita para o usuário monitor do PostgreSQL, preservando-o por padrão e exigindo opt-in para removê-lo, e verificar que a saída não expõe senha nem string de conexão.
- [x] 2.4 Adicionar status pós-destruição que verifica a ausência dos recursos de observabilidade e a preservação dos pré-requisitos externos, e verificar que a saída não contém segredos.

## 3. Migração do lifecycle de observabilidade

- [x] 3.1 Migrar e adaptar para o `espresso-observability` as tasks de Foundry, SigNoz, firewall, status e collector PostgreSQL, e verificar que `task --list` expõe descrições claras para instalar, consultar e destruir observabilidade.
- [x] 3.2 Migrar e adaptar os scripts de Foundry, SigNoz, firewall, status e collector para o executor SSH próprio, e verificar que a instalação é idempotente.
- [x] 3.3 Migrar e adaptar as variáveis de observabilidade para o `.env.example` do novo repositório, e verificar que o exemplo não contém credenciais sensíveis e que nenhuma variável específica de observabilidade é lida do infra.
- [x] 3.4 Migrar e adaptar a documentação operacional de arquitetura, SigNoz, collector e operação para o novo repositório, e verificar links internos, link para o infra e os comandos de install/status/destroy.

## 4. Redução da superfície do Espresso Infra

- [x] 4.1 Remover do `Taskfile.yml`, `tasks/`, `scripts/remote.sh` e `.env.example` do infra todas as tasks, dispatches e variáveis específicas de observabilidade, e verificar que `task --list` não oferece lifecycle de SigNoz ou collector.
- [x] 4.2 Remover scripts, documentos e referências internas de observabilidade que não pertencem mais ao infra, e verificar que não restam links locais quebrados nem instruções locais de instalação, status ou destruição.
- [x] 4.3 Atualizar README, arquitetura, operação, aplicação, Coolify e a documentação de integração do infra para referenciar `https://github.com/evellyncosta/espresso-observability`, e verificar que preservam apenas pré-requisitos e limites de responsabilidade do infra.
- [x] 4.4 Remover as specs-base `signoz-observability` e `postgres-observability-collector` do infra sem alterar changes arquivadas, e verificar que as specs restantes descrevem somente comportamento ainda pertencente ao repositório.

## 5. Validação de migração e DoD operacional

- [x] 5.1 Executar `destroy` a partir do `espresso-observability` contra a instalação SigNoz existente e verificar a ausência da stack/collector e a preservação de Coolify, Docker e PostgreSQL da aplicação.
- [x] 5.2 Instalar SigNoz e, quando aplicável, o collector PostgreSQL exclusivamente pelo `espresso-observability`, e verificar UI, containers, conectividade OTLP e status sem exposição de segredos.
- [x] 5.3 Executar novamente `destroy` exclusivamente pelo `espresso-observability`, e verificar que a VPS termina sem recursos de observabilidade e pronta para uma instalação manual posterior pelo operador.
- [x] 5.4 Executar validação estrita da change OpenSpec e as verificações de links/tasks relevantes nos dois repositórios, e verificar que todos os comandos retornam sucesso.

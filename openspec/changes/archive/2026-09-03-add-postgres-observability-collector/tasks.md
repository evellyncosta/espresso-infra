## 1. Configuração e Interface Pública

- [x] 1.1 Adicionar variáveis não sensíveis do collector ao `.env.example` e verificar que nenhum secret real foi adicionado.
- [x] 1.2 Adicionar task pública para instalar/verificar o collector do PostgreSQL em `tasks/observability.yml` e `Taskfile.yml`, e verificar que `task --list` exibe a task com descrição clara.

## 2. Script Remoto do Collector

- [x] 2.1 Implementar script remoto que cria o diretório operacional e o `.env` privado do collector na VPS, e verificar que o script não imprime a senha em logs.
- [x] 2.2 Implementar geração/reuso da senha do usuário monitor a partir do `.env` privado, e verificar que reexecuções preservam a senha existente.
- [x] 2.3 Implementar detecção ou configuração explícita do container PostgreSQL da aplicação gerenciado pelo Coolify, e verificar que ambiguidade ou ausência falha com mensagem clara.
- [x] 2.4 Implementar criação/reconciliação do usuário monitor entrando no container PostgreSQL do Coolify e usando a senha do `.env`, e verificar que a operação é idempotente.
- [x] 2.5 Implementar geração do `collector.yaml` e `docker-compose.yml` do collector, e verificar que os arquivos usam redes `coolify` e `signoz-network` sem incluir senha no YAML.
- [x] 2.6 Implementar deploy idempotente da stack Compose do collector, e verificar que o container sobe ou é atualizado sem apagar o `.env` privado.

## 3. Integração e Status

- [x] 3.1 Integrar o script ao roteamento de `scripts/remote.sh`, e verificar que a task local executa a ação remota correta.
- [x] 3.2 Atualizar `observability:status` para incluir o collector do PostgreSQL, e verificar que a saída não exibe senha, token ou string de conexão completa.

## 4. Documentação

- [x] 4.1 Atualizar `README.md` com task, variáveis, credencial privada na VPS, usuário monitor, deploy e limites de escopo, e verificar que o fluxo documentado não sugere commitar secrets.
- [x] 4.2 Atualizar `architecture.md` para incluir o collector do PostgreSQL e referência ao documento dedicado, e verificar que a separação entre Coolify, collector e SigNoz permanece clara.
- [x] 4.3 Criar `postgres_collector_archtecture.md` ao lado de `architecture.md` explicando somente o fluxo PostgreSQL -> collector -> SigNoz, e verificar que cobre `.env`, container Coolify, redes Docker e validação operacional.

## 5. Validação

- [x] 5.1 Executar validação estática local do Taskfile e scripts shell, e verificar que `bash -n scripts/*.sh` e `task --list` retornam sucesso.
- [x] 5.2 Validar a change OpenSpec em modo estrito e verificar que `openspec validate add-postgres-observability-collector --strict` retorna sucesso.

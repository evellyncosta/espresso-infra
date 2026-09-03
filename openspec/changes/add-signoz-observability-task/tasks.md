## 1. Configuração e Interface Pública

- [x] 1.1 Adicionar variáveis opcionais de observabilidade ao `.env.example` para URL/versão do Foundry, diretório do SigNoz, porta pública da UI do SigNoz e política de firewall, e verificar que nenhum secret real foi adicionado.
- [x] 1.2 Adicionar módulo de tasks de observabilidade e includes no `Taskfile.yml`, e verificar que `task --list` mostra `install:foundryctl`, `install:signoz` e `observability:status` com descrições claras.
- [x] 1.3 Decidir se `task setup` permanece sem SigNoz e adicionar um fluxo agregado opt-in para observabilidade quando aplicável, verificando que o fluxo base de Coolify continua funcionando sem instalar SigNoz.

## 2. Foundry/foundryctl

- [x] 2.1 Implementar script remoto para instalar ou verificar `foundryctl` usando o instalador suportado e versão pinada quando configurada, e verificar com `foundryctl --help` ou comando equivalente.
- [x] 2.2 Tornar a instalação de `foundryctl` idempotente para servidores onde o binário já existe, e verificar que uma segunda execução preserva a instalação e termina com sucesso.
- [x] 2.3 Integrar o script ao roteamento de `scripts/remote.sh`, e verificar que a task local executa a ação remota correta via SSH.

## 3. SigNoz

- [x] 3.1 Implementar script remoto de SigNoz que cria ou preserva o diretório configurado, mantém `casting.yaml` como fonte de verdade e verifica que Docker Compose está disponível antes de continuar.
- [x] 3.2 Gerar o `casting.yaml` mínimo para Foundry com `flavor: compose` e `mode: docker`, e verificar que o arquivo resultante existe no diretório configurado.
- [x] 3.3 Executar `foundryctl cast -f casting.yaml` para instalar ou atualizar SigNoz, e verificar que os containers esperados ficam em estado `Up` ou saudável.
- [x] 3.4 Tornar a task de SigNoz idempotente para instalações existentes gerenciadas por Foundry, e verificar que uma segunda execução preserva o casting e não apaga volumes.
- [x] 3.5 Adicionar preflight de memória mínima e conflitos de portas antes da primeira instalação, e verificar que falhas interrompem a task com mensagem acionável antes de alterar o estado do SigNoz.

## 4. Firewall e Status

- [x] 4.1 Atualizar a configuração de UFW para liberar portas documentadas do SigNoz conforme política configurada, e verificar que SSH, HTTP, HTTPS e portas do Coolify continuam permitidas.
- [x] 4.2 Evitar habilitar SigNoz MCP na primeira versão e documentar o conflito com a porta `8000`, verificando que nenhuma task abre ou depende do MCP.
- [x] 4.3 Implementar `observability:status` para exibir disponibilidade do `foundryctl`, containers SigNoz e acesso à UI quando possível, e verificar a saída em uma VPS com e sem SigNoz instalado.

## 5. Documentação e Arquitetura

- [x] 5.1 Atualizar o README com novas tasks, variáveis, portas, requisito de memória e fluxo de instalação de observabilidade, e verificar que o caminho documentado usa Foundry/foundryctl.
- [x] 5.2 Atualizar `architecture.md` para incluir SigNoz, OTLP gRPC/HTTP e relação com a aplicação Spring, PostgreSQL, Redis/Valkey e Coolify, e verificar que os diagramas Mermaid continuam válidos.
- [x] 5.3 Documentar endpoints esperados para a aplicação enviar telemetria ao SigNoz, e verificar que a documentação deixa claro que a instrumentação da aplicação está fora deste repositório.

## 6. Validação

- [x] 6.1 Executar validação estática local do Taskfile e scripts shell, e verificar que `bash -n scripts/*.sh` e `task --list` retornam sucesso em ambiente com Task instalado corretamente.
- [ ] 6.2 Executar as tasks de Foundry/foundryctl e SigNoz em uma VPS descartável compatível, e verificar que a UI do SigNoz responde na porta documentada.
- [ ] 6.3 Reexecutar as tasks em uma VPS já configurada, e verificar idempotência sem perda de configuração, volumes ou acesso ao Coolify.
- [x] 6.4 Verificar higiene de secrets no repositório, e confirmar que nenhum token, senha, chave privada ou API key foi adicionado a arquivos rastreados.

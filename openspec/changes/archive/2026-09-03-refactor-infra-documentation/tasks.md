## 1. Estrutura da Documentacao

- [x] 1.1 Criar a pasta publica `docs/` com arquivos alvo `architecture.md`, `application.md`, `coolify.md`, `signoz.md`, `postgres-collector.md` e `operations.md`, e verificar que todos os arquivos existem no caminho esperado.
- [x] 1.2 Definir titulos e links cruzados basicos entre os documentos em `docs/`, e verificar que cada documento aponta de volta ao README ou ao documento relacionado quando aplicavel.

## 2. Migracao de Conteudo Existente

- [x] 2.1 Mover o conteudo de `architecture.md` para `docs/architecture.md`, ajustar referencias internas, e verificar que os diagramas e links continuam coerentes.
- [x] 2.2 Mover e renomear `postgres_collector_archtecture.md` para `docs/postgres-collector.md`, preservar o conteudo operacional relevante, corrigir o typo do nome antigo, e verificar que nao ha links internos apontando para o arquivo antigo.
- [x] 2.3 Extrair detalhes de Coolify do README para `docs/coolify.md`, e verificar que acesso inicial, portas diretas, responsabilidades e servicos gerenciados estao documentados.
- [x] 2.4 Extrair detalhes de SigNoz do README para `docs/signoz.md`, e verificar que Foundry/foundryctl, diretorio, memoria, portas, OTLP, firewall e limites fora de escopo estao documentados.
- [x] 2.5 Extrair tasks, variaveis, portas e fluxos recorrentes do README para `docs/operations.md`, e verificar que os comandos publicos e variaveis conhecidas continuam cobertos.

## 3. Aplicacao Externa

- [x] 3.1 Criar `docs/application.md` referenciando `https://github.com/evellyncosta/espresso-api`, e verificar que o documento deixa claro que a aplicacao vive em outro repositorio.
- [x] 3.2 Documentar em `docs/application.md` a fronteira entre aplicacao, Coolify e este repo de infra, e verificar que dependencias runtime conhecidas incluem PostgreSQL, Redis/Valkey e SigNoz/OTLP sem expor secrets reais.

## 4. README

- [x] 4.1 Reescrever o README como overview geral com proposta, limites, pre-requisitos e quickstart minimo, e verificar que ele nao duplica listas longas de variaveis, portas ou detalhes operacionais.
- [x] 4.2 Adicionar ao README um sumario para todos os documentos em `docs/`, e verificar que os links apontam para arquivos existentes.

## 5. Validacao

- [x] 5.1 Procurar referencias aos nomes antigos `architecture.md` e `postgres_collector_archtecture.md`, e verificar que referencias remanescentes sao intencionais ou foram atualizadas.
- [x] 5.2 Verificar higiene de secrets nos documentos alterados, e confirmar que nenhum token, senha, chave privada ou API key real foi adicionado.
- [x] 5.3 Revisar a documentacao final do ponto de vista de um operador novo, e verificar que README, aplicacao, Coolify, SigNoz, collector PostgreSQL, operacao e arquitetura estao navegaveis sem informacao duplicada em excesso.

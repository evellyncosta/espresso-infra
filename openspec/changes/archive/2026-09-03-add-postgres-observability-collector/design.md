## Context

Veja `proposal.md` para a motivação. O repositório já provisiona SigNoz via Foundry/foundryctl e mantém a stack de observabilidade separada do Coolify. Na VPS atual, o PostgreSQL da aplicação Espresso está em um container gerenciado pelo Coolify na rede Docker `coolify`, enquanto o SigNoz roda na rede Docker `signoz-network`.

O receiver `postgresql` do OpenTelemetry Collector precisa de usuário, senha e permissões de leitura em estatísticas do PostgreSQL. Essas credenciais não devem ser copiadas para o repositório nem depender de variáveis exportadas de dentro do container Postgres.

## Goals / Non-Goals

**Goals:**

- Provisionar um collector dedicado para métricas do PostgreSQL da aplicação.
- Persistir a senha do usuário monitor em um `.env` privado na VPS.
- Aplicar essa senha no PostgreSQL entrando no container gerenciado pelo Coolify.
- Conectar o collector às redes `coolify` e `signoz-network`.
- Enviar métricas ao `signoz-ingester` por OTLP interno.
- Documentar o fluxo em `README.md`, `architecture.md` e `postgres_collector_archtecture.md`.

**Non-Goals:**

- Instrumentar a aplicação Spring.
- Coletar query samples, top queries ou planos de query na primeira versão.
- Habilitar `pg_stat_statements` automaticamente.
- Alterar o Compose, lifecycle ou secrets gerenciados pelo Coolify.
- Alterar o collector interno gerado pelo Foundry para o SigNoz.

## Decisions

### Usar collector dedicado em vez de alterar o collector interno do SigNoz

A implementação deve subir uma stack Compose própria para o collector do PostgreSQL, em diretório operacional dedicado fora de `/data/signoz/pours`.

Racional: o `signoz-ingester` é componente crítico da stack SigNoz gerada pelo Foundry. Um erro no receiver do PostgreSQL não deve derrubar a ingestão principal de traces, logs e métricas da aplicação.

Alternativa considerada: adicionar o receiver `postgresql` ao config do `signoz-ingester`. Isso reduz um container, mas aumenta o acoplamento e o risco de quebrar a stack SigNoz durante reconfigurações do banco.

### Usar `.env` privado na VPS como fonte da senha do usuário monitor

A senha deve nascer no host da VPS, ser armazenada em arquivo operacional privado do collector e ser usada tanto para configurar o collector quanto para criar ou reconciliar o role no PostgreSQL.

Racional: variáveis de ambiente dentro do container Postgres não são uma forma confiável de exportar estado para o host. Guardar a senha no host, fora do repositório, cria uma fonte persistente e rotacionável.

Alternativa considerada: ler secrets do Coolify ou reaproveitar senha administrativa do banco. Isso aumenta acoplamento e expõe uma credencial mais privilegiada do que o collector precisa.

### Criar/reconciliar o usuário via container PostgreSQL do Coolify

O script remoto deve localizar o container PostgreSQL da aplicação, executar `psql` dentro dele e aplicar `CREATE ROLE` ou `ALTER ROLE` usando a senha do `.env` privado.

Racional: o Postgres da aplicação não publica `5432` no host. Entrar pelo container gerenciado pelo Coolify permite usar o ambiente local do próprio serviço sem expor portas novas.

Alternativa considerada: publicar o Postgres no host e provisionar a credencial externamente. Isso amplia superfície de rede e não é necessário para a coleta.

### Manter coleta inicial restrita a métricas básicas

A primeira versão deve habilitar apenas métricas básicas do receiver PostgreSQL e permissões mínimas para leitura de estatísticas.

Racional: query samples, top queries e planos podem expor texto de queries e exigem permissões/extensões adicionais. Isso merece uma change própria com análise de segurança.

## Risks / Trade-offs

- Container Postgres errado identificado -> usar labels e variáveis explícitas para restringir o alvo, e falhar quando houver ambiguidade.
- Senha impressa em logs por acidente -> nunca ecoar o valor da senha, nem imprimir strings de conexão completas.
- Role reconciliado com senha antiga após edição manual -> tratar o `.env` privado como fonte operacional da senha e documentar rotação futura.
- Collector sem acesso à rede correta -> validar `coolify` e `signoz-network` antes de subir o Compose.
- Permissões mínimas insuficientes para algumas métricas -> manter coleta avançada fora do escopo inicial e documentar a limitação.

## Migration Plan

1. Adicionar variáveis não sensíveis do collector no `.env.example`.
2. Criar script remoto para preparar o diretório operacional, o `.env` privado, o role de monitoramento no Postgres e a stack Compose do collector.
3. Integrar o script ao roteamento de `scripts/remote.sh` e às tasks de observabilidade.
4. Atualizar status de observabilidade para incluir o collector do PostgreSQL.
5. Atualizar `README.md` e `architecture.md`.
6. Criar `postgres_collector_archtecture.md` com o fluxo dedicado.
7. Validar sintaxe local dos scripts, listagem de tasks e, quando possível, o deploy remoto idempotente.

Rollback operacional: parar e remover apenas a stack Compose do collector. O role de monitoramento pode ser mantido para reuso ou removido manualmente do PostgreSQL após decisão explícita do operador.

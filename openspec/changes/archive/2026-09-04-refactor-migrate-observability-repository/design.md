## Context

See `proposal.md` for motivation. O Espresso Infra hoje contém o fluxo remoto completo de observabilidade: variáveis no ambiente, dispatcher SSH, tasks, scripts, documentação e specs de SigNoz e do collector PostgreSQL. O repositório `espresso-observability` já possui raiz OpenSpec, mas não terá specs ou ADRs migrados; ele receberá apenas código e documentação operacional reescrita para sua responsabilidade.

## Goals / Non-Goals

**Goals:**

- Transferir o ownership operacional de observabilidade para `espresso-observability` sem acoplar seu código a caminhos locais do repositório infra.
- Deixar o Espresso Infra responsável apenas por VPS, Docker, firewall base e Coolify, com referências claras ao repositório externo.
- Introduzir no novo repositório uma destruição explícita, idempotente e limitada aos recursos de observabilidade.
- Provar o lifecycle do novo repositório por meio de `destroy -> install -> validar -> destroy` e deixar a instalação ausente ao término.

**Non-Goals:**

- Copiar specs, ADRs, changes arquivadas ou decisões históricas para o novo repositório.
- Alterar a instalação, configuração, redes, dados ou lifecycle do Coolify, PostgreSQL da aplicação, Redis/Valkey ou Docker base.
- Remover o usuário monitor do PostgreSQL sem uma decisão e comportamento explícitos na task `destroy`.
- Instalar novamente a plataforma pelo Espresso Infra depois que a migração começar.

## Decisions

### Novo repositório como fonte operacional exclusiva

As tasks, scripts remotos, exemplo de ambiente e documentação de SigNoz/collector serão recriados no repositório `espresso-observability`. O executor SSH será próprio, mesmo que inicialmente se pareça com o do infra, para evitar dependência de checkout, caminho ou release sincronizados.

Alternativa considerada: o novo repositório invocar scripts do Espresso Infra. Foi descartada porque preserva o acoplamento que a refatoração pretende eliminar.

### Infra conserva somente contratos e referências

O `Taskfile.yml`, `.env.example`, `scripts/remote.sh`, README e documentos do infra removem os elementos específicos de observabilidade. A documentação mantém um link para o novo repositório e descreve somente pré-requisitos fornecidos: SSH, Docker/Compose e, para o collector, Coolify, PostgreSQL e rede Docker existentes.

Alternativa considerada: manter aliases de compatibilidade no infra. Foi descartada porque manteria duas superfícies de lifecycle e tornaria ambígua a fonte de verdade.

### Destruição é uma task de primeira classe no novo repositório

A task `destroy` deve detectar a instalação antes de remover recursos e concluir com sucesso quando ela já estiver ausente. Seu escopo é limitado à stack SigNoz/Foundry, collector PostgreSQL, diretórios operacionais e regras de firewall específicas de observabilidade. A política para o usuário monitor do PostgreSQL deve ser exposta e documentada, nunca implícita.

Alternativa considerada: remoção manual ad hoc na VPS. Foi descartada porque não valida o repositório que assumirá o lifecycle e não fornece uma operação repetível para o futuro.

### Sem migração de specs ou ADRs

Specs ativas de SigNoz e collector são removidas do infra porque não representarão mais comportamento deste projeto. O novo repositório começa sem specs e ADRs; novas features poderão introduzi-las de acordo com suas próprias mudanças. Changes arquivadas ficam no infra como registro histórico e não são transferidas.

## Risks / Trade-offs

- [Destruição identificar containers por nome amplo] -> usar identificação baseada na instalação gerada pelo Foundry, diretórios configurados e labels/nomes validados; abortar em alvos ambíguos.
- [Remover uma regra UFW não pertencente ao SigNoz] -> remover somente regras com comentário/porta e identidade esperados, mostrando o plano antes de alterar regras ambíguas.
- [Collector deixar credencial ou role órfãos] -> definir e documentar a política para o `.env` privado, container e usuário monitor; a operação não remove a role sem opt-in explícito.
- [Instalação do novo repo depender de detalhe não documentado do infra] -> executar o ciclo de aceite numa VPS existente e registrar todos os pré-requisitos no documento de integração.
- [Links e documentação do infra ficarem obsoletos] -> validar links locais e externos após remover documentos e comandos de observabilidade.

## Migration Plan

1. Criar no `espresso-observability` a estrutura operacional mínima, sem specs nem ADRs, e implementar `destroy` antes das demais tasks.
2. Migrar e adaptar as tarefas de instalação, status, firewall, SigNoz e collector, juntamente com documentação e exemplo de ambiente próprios.
3. Remover a superfície de observabilidade do Espresso Infra e substituir referências internas por links para o novo repositório.
4. Na VPS alvo, executar `destroy` a partir do novo repositório para remover a instalação atual; verificar que componentes fora de escopo permanecem ativos.
5. Executar a instalação pelo novo repositório e validar SigNoz, collector quando aplicável, conectividade e ausência de segredos na saída.
6. Executar novamente `destroy` pelo novo repositório e validar que a VPS termina sem recursos de observabilidade, pronta para instalação posterior pelo operador.

Rollback: antes da etapa final de destruição, uma falha pode ser corrigida repetindo a instalação pelo novo repositório. Após a destruição final, a recuperação suportada é executar novamente a instalação pelo novo repositório; não há rollback por preservação da stack removida.

## Context

O repositório concentra a documentação operacional em `docs/`, mas não possui um local nem uma estrutura uniforme para decisões arquiteturais. A motivação da mudança está em [proposal.md](proposal.md).

Esta mudança documenta uma decisão já tomada no painel da Contabo: existe uma Private Network disponível para a infraestrutura. Ela não conecta o computador do operador à VPS e não é a rede virtual do WireGuard.

## Goals / Non-Goals

**Goals:**

- Estabelecer uma convenção leve e local para ADRs versionadas com o repositório.
- Registrar o escopo presente e o uso futuro esperado da Private Network sem introduzir detalhes sensíveis ou prematuros.
- Distinguir comunicação interna entre máquinas da Contabo de acesso administrativo remoto por WireGuard.

**Non-Goals:**

- Conectar novas VPSs à Private Network ou configurar endereços, rotas e regras de firewall.
- Instalar ou configurar WireGuard, UFW, firewall da Contabo ou Coolify.
- Definir uma topologia definitiva de múltiplas VPSs ou reservar intervalos de IP reais.

## Decisions

### ADRs ficam sob `docs/adrs/`

O diretório usará nomes com número sequencial de três dígitos e um identificador descritivo, começando por `001-private-network-contabo.md`. Um `README.md` será o índice e um `template.md` será a fonte para novas decisões.

Alternativa considerada: manter decisões apenas nas mudanças OpenSpec. Rejeitada porque as mudanças são temporárias e focadas no planejamento; ADRs precisam permanecer como referência arquitetural duradoura após o arquivamento.

### A ADR 001 limita a decisão à comunicação interna futura

A decisão afirma que futuras VPSs e serviços anexados à Private Network devem preferir essa rede para tráfego leste-oeste. Ela não declara a rede como mecanismo atual de acesso remoto nem presume máquinas que ainda não existem.

Alternativa considerada: documentar a Private Network como uma VPN de administração. Rejeitada porque ela não cria um túnel entre o computador do operador e a VPS.

### WireGuard é uma decisão complementar, não substituída

A ADR diferencia a sobreposição WireGuard, adequada para SSH, Coolify e outros acessos administrativos remotos, da Private Network da Contabo. A implementação futura de WireGuard deve ganhar uma ADR e um procedimento operacional próprios quando entrar no escopo.

Alternativa considerada: tratar apenas WireGuard nesta ADR. Rejeitada porque o gatilho desta decisão é a disponibilidade de uma rede privada entre recursos da Contabo, com objetivo diferente.

## Risks / Trade-offs

- [A Private Network criada ficar sem uso por algum tempo] -> Registrar expressamente que ela só se torna funcional para novos hosts depois de serem anexados, endereçados e protegidos por firewall.
- [Uma ADR sugerir que serviços já estão isolados] -> Distinguir estado atual, intenção futura e atividades fora de escopo.
- [Divulgação acidental de detalhes operacionais] -> Usar exemplos genéricos e proibir IPs, IDs, credenciais e chaves reais.

## Migration Plan

1. Criar a estrutura de ADRs e a ADR 001.
2. Incluir o índice de ADRs no README.
3. Em mudanças futuras que adicionarem máquinas Contabo, referenciar a ADR 001 e definir os IPs, rotas e políticas de firewall apropriados.

Não há migração de runtime nem rollback operacional. Caso a documentação precise ser revertida, remover apenas os arquivos desta mudança e o link correspondente do README em um commit de reversão.

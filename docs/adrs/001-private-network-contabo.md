# ADR 001 — Usar a Private Network da Contabo para comunicação interna futura

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

A infraestrutura atual opera em uma única VPS Contabo, mas uma Private Network já foi criada para permitir a evolução para múltiplas máquinas e serviços internos no mesmo provedor. Sem uma rede privada compartilhada, a comunicação entre esses recursos tende a depender de interfaces públicas, ampliando a superfície exposta e misturando tráfego interno com tráfego da Internet.

A Private Network da Contabo não é uma VPN de acesso remoto: ela não conecta o computador do operador à VPS. Ela também não substitui o WireGuard, que é a solução apropriada para criar um túnel criptografado entre o operador e a infraestrutura para fins administrativos.

## Decisão

Futuras VPSs e serviços internos hospedados na Contabo devem ser anexados à Private Network e devem preferir essa rede para comunicação entre máquinas, quando a separação de responsabilidades exigir mais de um host.

A rede criada será mantida como base para essa evolução. No estado atual, ela não altera o acesso à VPS nem indica que serviços existentes já estejam isolados por ela.

## Alternativas consideradas

### Manter comunicação entre máquinas por interfaces públicas

Rejeitada porque exige expor serviços ou depender de regras públicas entre hosts, aumenta a superfície de ataque e torna mais difícil distinguir tráfego interno de tráfego externo.

### Usar somente WireGuard

Rejeitada porque WireGuard resolve acesso remoto por túnel entre peers autorizados, mas não substitui uma rede privada nativa para comunicação contínua entre futuras máquinas da Contabo.

### Adiar a criação da Private Network

Rejeitada porque a rede já existe e registrar a intenção agora estabelece uma direção antes que novas VPSs introduzam conexões públicas por conveniência.

## Consequências

Benefícios esperados:

- reduzir a exposição de tráfego leste-oeste à Internet pública;
- permitir separar aplicação, observabilidade, dados ou outros serviços em máquinas distintas;
- tornar explícita a responsabilidade de definir quais serviços são internos e quais permanecem públicos.

Cada nova máquina anexada à rede deverá receber endereçamento privado planejado, rotas necessárias e regras restritivas tanto no firewall local quanto no firewall do provedor. Serviços internos não devem ser publicados por padrão apenas porque participam da rede privada.

O acesso administrativo remoto continua sendo uma preocupação separada. Uma futura decisão e procedimento operacional para WireGuard deverão definir como SSH, Coolify e outros serviços administrativos serão restringidos.

## Implementação

Esta ADR não configura recursos de runtime. Quando uma mudança futura adicionar uma VPS ou serviço que precise de comunicação interna, ela deverá:

1. anexar o recurso à Private Network;
2. definir o endereçamento e as rotas privadas necessários;
3. limitar no firewall os serviços destinados apenas à comunicação interna;
4. documentar quais interfaces e serviços precisam continuar disponíveis publicamente;
5. referenciar esta ADR e validar a conectividade e o isolamento esperados.

## Critérios de revisão

Revisar esta decisão quando a primeira máquina adicional for anexada à Private Network, quando uma topologia fora da Contabo exigir conectividade privada ou quando a estratégia de acesso administrativo por WireGuard for formalizada. Se uma decisão posterior a substituir, atualizar o status para `Substituído` e apontar para a ADR sucessora.

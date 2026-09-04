# ADR 002 — Restringir o acesso administrativo ao Coolify pela VPN

- **Status:** Aceito
- **Data:** 2026-09-04

## Contexto

As aplicações hospedadas no Coolify precisam continuar disponíveis publicamente por HTTP e HTTPS. Em contrapartida, o painel do Coolify, seus serviços auxiliares de acesso direto e o SSH são interfaces administrativas e não devem permanecer acessíveis pela Internet depois da configuração inicial.

A Private Network da Contabo, tratada na [ADR 001](001-private-network-contabo.md), é destinada à comunicação entre recursos do provedor e não conecta o computador do operador à VPS. O acesso administrativo remoto exige um túnel entre o operador e a VPS; WireGuard atende a esse propósito.

## Decisão

O acesso administrativo à VPS será restrito à VPN WireGuard. SSH e as portas diretas do Coolify (`8000/tcp`, `6001/tcp` e `6002/tcp`) devem aceitar conexões apenas da rede WireGuard autorizada.

As aplicações permanecerão publicamente acessíveis por `80/tcp` e `443/tcp`. A porta `51820/udp` permanece pública exclusivamente para estabelecer o túnel WireGuard. A política de firewall pública deve usar negação por padrão.

O procedimento de configuração, validação e retirada segura do acesso público está em [Coolify acessível somente via VPN](../coolify-vpn-access.md).

## Alternativas consideradas

### Manter SSH e painel do Coolify públicos

Rejeitada porque amplia a superfície de ataque das interfaces administrativas e permite tentativas de acesso fora do canal administrativo autorizado.

### Usar a Private Network da Contabo para o acesso do operador

Rejeitada porque essa rede conecta recursos hospedados na Contabo, não o computador local do operador à VPS.

### Bloquear as portas administrativas antes de validar o WireGuard

Rejeitada porque pode causar perda de acesso à VPS. A VPN deve ser testada com handshake, acesso ao painel e SSH antes da remoção das regras públicas.

## Consequências

Benefícios esperados:

- reduzir a exposição pública de SSH e do painel, realtime e terminal do Coolify;
- preservar o acesso público das aplicações por HTTP e HTTPS;
- separar explicitamente o tráfego administrativo do tráfego de usuários das aplicações.

Operadores precisam ativar a VPN WireGuard antes de acessar SSH ou as portas administrativas do Coolify. A indisponibilidade da VPN impede esses acessos até que o túnel seja recuperado; por isso, a configuração deve manter um caminho de recuperação autorizado pelo provedor e ser alterada somente após os testes descritos no manual.

## Implementação

Aplicar o [manual de acesso do Coolify pela VPN](../coolify-vpn-access.md) na ordem indicada:

1. manter temporariamente as portas administrativas abertas enquanto configura o WireGuard;
2. liberar a porta WireGuard no firewall do provedor e no UFW;
3. permitir SSH e as portas administrativas apenas para a sub-rede WireGuard;
4. validar handshake, painel e SSH pelo túnel;
5. remover as permissões públicas administrativas no UFW e no firewall da Contabo.

Esta ADR não inclui chaves privadas, credenciais, IPs públicos reais nem identificadores da conta Contabo. A automação dessas configurações permanece fora de escopo.

## Critérios de revisão

Revisar esta decisão quando houver mudança de provedor, de solução de VPN, de topologia de administração, de portas expostas pelo Coolify ou de requisito de acesso administrativo de emergência. Caso outra ADR a substitua, atualizar o status para `Substituído` e adicionar o link para a ADR sucessora.

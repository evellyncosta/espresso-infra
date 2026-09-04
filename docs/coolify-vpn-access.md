# Coolify acessível somente via VPN

Este manual descreve como manter as aplicações hospedadas no Coolify acessíveis publicamente pelas portas `80` e `443`, enquanto o painel do Coolify e o SSH ficam acessíveis somente pela VPN WireGuard.

Voltar para o [README](../README.md). Consulte também a [ADR 002 — Restringir o acesso administrativo ao Coolify pela VPN](adrs/002-coolify-access-via-vpn.md).

> Os endereços, chaves e IP público abaixo são exemplos. Não registre chaves privadas, credenciais ou o IP público real da VPS neste repositório.

## 1. Firewall da Contabo

Configure o firewall pelo painel da Contabo e associe-o à VPS.

Durante a configuração inicial, mantenha temporariamente abertas:

- `22/tcp` — SSH
- `80/tcp` — aplicações HTTP
- `443/tcp` — aplicações HTTPS
- `8000/tcp` — painel do Coolify
- `51820/udp` — WireGuard

As portas administrativas não devem ser bloqueadas neste momento, para evitar perda de acesso ao servidor durante a configuração da VPN.

## 2. Instalação do WireGuard

Instale o WireGuard nos dois lados da conexão:

- VPS Contabo;
- computador local do operador.

Defina uma rede privada do WireGuard. Neste procedimento, a rede de exemplo é:

```text
Servidor:    10.66.66.1
Computador:  10.66.66.2
Rede:        10.66.66.0/24
```

Essa faixa pertence à VPN WireGuard configurada neste procedimento. Ela não é a Private Network fornecida pela Contabo; a Private Network é destinada à comunicação entre recursos do provedor, conforme a [ADR 001](adrs/001-private-network-contabo.md).

## 3. Configuração das chaves

Cada lado possui seu próprio par de chaves:

```text
Servidor
├── chave privada
└── chave pública

Computador
├── chave privada
└── chave pública
```

As chaves privadas nunca saem do dispositivo onde foram criadas. Troque somente as chaves públicas:

```text
Chave pública do servidor
        ↓
configuração do computador

Chave pública do computador
        ↓
configuração do servidor
```

No servidor, use uma configuração equivalente a:

```ini
[Interface]
Address = 10.66.66.1/24
PrivateKey = <CHAVE_PRIVADA_DO_SERVIDOR>
ListenPort = 51820

[Peer]
PublicKey = <CHAVE_PUBLICA_DO_COMPUTADOR>
AllowedIPs = 10.66.66.2/32
```

No computador, use uma configuração equivalente a:

```ini
[Interface]
Address = 10.66.66.2/24
PrivateKey = <CHAVE_PRIVADA_DO_COMPUTADOR>

[Peer]
PublicKey = <CHAVE_PUBLICA_DO_SERVIDOR>
Endpoint = <IP_PUBLICO_DA_VPS>:51820
AllowedIPs = 10.66.66.1/32
PersistentKeepalive = 25
```

## 4. Configuração do UFW

No servidor, mantenha públicas as portas necessárias às aplicações e ao túnel:

```text
80/tcp
443/tcp
51820/udp
```

Permita as portas administrativas somente para a rede WireGuard:

```text
22/tcp      ← 10.66.66.0/24
8000/tcp    ← 10.66.66.0/24
6001/tcp    ← 10.66.66.0/24
6002/tcp    ← 10.66.66.0/24
```

Libere também `51820/udp` no UFW. Sem essa regra, o firewall pode bloquear o handshake do WireGuard.

## 5. Testes da VPN

Ative o WireGuard e valide o handshake no servidor:

```bash
sudo wg
```

Confirme a comunicação pela rede privada e teste o painel do Coolify:

```bash
curl -I http://10.66.66.1:8000
```

Teste também o SSH pela VPN:

```bash
ssh root@10.66.66.1
```

Somente após confirmar handshake, painel e SSH pela VPN, inicie o bloqueio do acesso público.

## 6. Remoção do acesso público

Remova do UFW as permissões públicas para:

```text
22/tcp
8000/tcp
6001/tcp
6002/tcp
```

No firewall da Contabo, desative também o acesso público a:

```text
22/tcp
8000/tcp
```

Mantenha a política pública final:

```text
80/tcp       → público
443/tcp      → público
51820/udp    → público
DEFAULT      → DROP
```

## Resultado final

```text
Internet
│
├── 80/tcp ──────→ aplicações públicas
├── 443/tcp ─────→ aplicações públicas
└── 51820/udp ───→ WireGuard
                       │
                       ▼
                 VPN 10.66.66.0/24
                       │
                       ├── 22/tcp ───→ SSH
                       ├── 8000/tcp ─→ Coolify
                       ├── 6001/tcp ─→ Coolify realtime
                       └── 6002/tcp ─→ Coolify terminal
```

Valide que o painel não responde pelo IP público:

```bash
curl --connect-timeout 5 -I http://<IP_PUBLICO_DA_VPS>:8000
```

O resultado esperado é um timeout de conexão. O acesso privado deve continuar funcionando em:

```text
http://10.66.66.1:8000
```

Assim, Coolify e SSH permanecem restritos à VPN, enquanto as aplicações continuam disponíveis publicamente em `80/443`.

## Why

O acesso inicial a uma VPS Contabo envolve tres credenciais diferentes — VNC, root e chave SSH — e uma sequencia incorreta pode deixar o operador sem acesso remoto. Um guia operacional em portugues reduz ambiguidades, facilita a recuperacao via VNC e estabelece o uso seguro de autenticacao por chave no Linux.

## What Changes

- Adicionar um guia em `docs/` para provisionar uma VPS Contabo e acessa-la inicialmente a partir de um computador Linux.
- Documentar a configuracao da console VNC no painel da Contabo e a conexao pelo Remmina usando o IP publico da VPS.
- Distinguir explicitamente senha VNC, senha do usuario `root`, chave SSH publica e chave SSH privada.
- Documentar a criacao da chave ED25519 local, a instalacao com `ssh-copy-id` e o teste de acesso SSH.
- Incluir a verificacao de fingerprint do host e o procedimento seguro para remover uma entrada antiga de `known_hosts` apos uma recriacao intencional da VPS.

## Capabilities

### New Capabilities

- Nenhuma. Esta mudanca apenas adiciona documentacao operacional e nao altera comportamento do sistema.

### Modified Capabilities

- Nenhuma.

## Impact

- Adiciona um novo arquivo Markdown sob `docs/`.
- Nao altera infraestrutura provisionada, configuracoes runtime, APIs, dependencias ou secrets.

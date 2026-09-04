## 1. Guia de acesso inicial

- [x] 1.1 Criar `docs/contabo-vps-access.md` com pre-requisitos e o fluxo de provisionamento, VNC no Remmina e login root; verificar que o documento diferencia IP publico da VPS, senha VNC e senha root.
- [x] 1.2 Documentar geracao local da chave ED25519, instalacao por `ssh-copy-id` e teste de login SSH; verificar que a chave privada nunca e indicada como conteudo a ser enviado para a VPS.

## 2. Seguranca e validacao

- [x] 2.1 Adicionar orientacao para validar a fingerprint pela console VNC e remover uma entrada antiga de `known_hosts` somente apos a comparacao; verificar que o guia nao sugere desabilitar permanentemente a verificacao de host.
- [x] 2.2 Revisar o Markdown final quanto a comandos copiaveis, links relativos e ausencia de IPs, senhas ou chaves reais; verificar com uma leitura completa do arquivo e `git diff --check`.

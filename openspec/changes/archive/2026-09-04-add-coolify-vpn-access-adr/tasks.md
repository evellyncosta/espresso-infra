## 1. Manual operacional

- [x] 1.1 Criar `docs/coolify-vpn-access.md` com o procedimento de firewall da Contabo, instalação e chaves WireGuard, regras UFW, testes e remoção do acesso público; verificar que documenta a política final de portas públicas e administrativas sem valores sensíveis.
- [x] 1.2 Incluir no manual os comandos de validação de handshake, HTTP privado, SSH privado e bloqueio do painel pelo IP público; verificar que a ordem valida a VPN antes de remover permissões públicas.

## 2. ADR e navegação

- [x] 2.1 Criar `docs/adrs/002-coolify-access-via-vpn.md` a partir do template, registrando a restrição de SSH e Coolify à VPN WireGuard; verificar que a ADR contém contexto, decisão, alternativas, consequências, implementação e critérios de revisão.
- [x] 2.2 Adicionar na ADR um link Markdown relativo para `../coolify-vpn-access.md`; verificar que o destino existe e que o link pode ser resolvido a partir de `docs/adrs/`.
- [x] 2.3 Atualizar `docs/adrs/README.md` com a ADR 002 e `docs/coolify.md` com referência à política de acesso por VPN; verificar que a numeração, status e links são consistentes.

## 3. Revisão documental

- [x] 3.1 Revisar os arquivos criados e alterados para distinguir a rede WireGuard da Private Network da Contabo; verificar que nenhuma instrução declara que a Private Network fornece acesso remoto.
- [x] 3.2 Validar os links internos e procurar conteúdo sensível nos documentos adicionados; verificar que links apontam para arquivos existentes e que não há chaves privadas, credenciais, IP público real ou identificadores de conta.

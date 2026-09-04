## 1. Estrutura de ADRs

- [x] 1.1 Criar `docs/adrs/README.md` com índice, convenção de numeração de três dígitos e estados de ADR; verificar que o arquivo referencia o template e a ADR 001.
- [x] 1.2 Criar `docs/adrs/template.md` com título, status, data, contexto, decisão, alternativas consideradas, consequências, implementação e critérios de revisão; verificar que todos os campos estão presentes e não contêm dados específicos da Contabo.

## 2. Decisão de Private Network

- [x] 2.1 Criar `docs/adrs/001-private-network-contabo.md` para registrar o uso futuro da Private Network da Contabo entre VPSs e serviços internos; verificar que diferencia a rede de WireGuard e não contém IPs, IDs, credenciais ou chaves reais.
- [x] 2.2 Documentar na ADR benefícios, alternativas, consequências e pré-requisitos para conectar futuras máquinas; verificar que nenhuma configuração de runtime é declarada como já aplicada.

## 3. Descoberta e revisão

- [x] 3.1 Adicionar um link para `docs/adrs/README.md` ao README; verificar que o link relativo é válido e que a seção de documentação mantém os demais links existentes.
- [x] 3.2 Revisar os documentos Markdown criados e o README para consistência terminológica; verificar com `rg -n 'IP|PrivateKey|PublicKey|credential|senha' docs/adrs` que não há detalhes sensíveis incluídos por engano.

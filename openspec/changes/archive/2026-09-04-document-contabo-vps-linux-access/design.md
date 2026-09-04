## Context

O repositorio ja concentra a documentacao operacional em `docs/`. Esta mudanca adiciona um guia de acesso inicial a VPS para operadores Linux. O guia precisa cobrir a sequencia entre console VNC e SSH sem tratar a chave privada como um artefato a ser enviado ao servidor. Veja a motivacao em `proposal.md`.

## Goals / Non-Goals

**Goals:**

- Produzir um procedimento linear, executavel e seguro para o primeiro acesso.
- Explicar qual credencial pertence a cada etapa e onde ela deve ser usada.
- Incluir o tratamento seguro para a mudanca esperada de host key apos uma recriacao da VPS.

**Non-Goals:**

- Automatizar o provisionamento da Contabo.
- Alterar configuracao do SSHD, firewall ou politicas de autenticacao da VPS.
- Documentar recuperacao completa pelo Rescue System ou procedimentos para outros sistemas operacionais locais.

## Decisions

### Um guia dedicado em `docs/`

O guia sera criado como `docs/contabo-vps-access.md`, proximo da documentacao operacional existente. Isso evita sobrecarregar o README e permite que o procedimento tenha contexto e alertas de seguranca suficientes.

Alternativa considerada: adicionar as instrucoes ao README. Rejeitada porque o README e um overview, enquanto este fluxo exige comandos e verificacoes operacionais detalhadas.

### Credenciais separadas por finalidade

O documento tratara senha VNC, senha de `root`, chave publica SSH e chave privada SSH como itens independentes, indicando em qual lado cada um e usado. A chave privada nunca deve ser copiada para a VPS.

Alternativa considerada: descrever apenas os comandos. Rejeitada porque e facil confundir a senha de VNC com a senha do sistema e comprometer a chave privada.

### Confirmacao explicita de host key

Antes de executar `ssh-keygen -R`, o guia manda comparar a fingerprint exibida no cliente com a chave publica do host obtida na console VNC. So apos essa verificacao a entrada antiga de `known_hosts` e removida.

Alternativa considerada: sugerir `StrictHostKeyChecking=no`. Rejeitada por ocultar um possivel ataque de intermediario.

## Risks / Trade-offs

- [Interfaces e opcoes do painel Contabo podem mudar] -> Referir-se a conceitos estaveis (VNC, redefinicao de senha e IP publico) e evitar depender de rotulos exatos da interface.
- [Layout de teclado da VNC pode alterar caracteres de senha] -> Recomendar uma senha temporaria sem simbolos durante a recuperacao e alertar para digitacao manual.
- [Host key alterada pode indicar ataque] -> Exigir a comparacao da fingerprint pela VNC antes de substituir `known_hosts`.

# Acesso inicial a uma VPS Contabo pelo Linux

Este guia mostra como acessar uma VPS recém-provisionada pela console VNC e, depois, configurar o acesso SSH por chave a partir de um computador Linux.

Voltar para o [README](../README.md). Consulte também o guia de [Operação](operations.md).

## Credenciais usadas neste fluxo

| Item | Onde é usado | Não confundir com |
| --- | --- | --- |
| Senha VNC | Remmina, para abrir a console remota | Senha do sistema da VPS |
| Senha de `root` | Tela de login dentro da console VNC e, se permitido, primeiro login SSH | Senha VNC |
| Chave pública SSH | Copiada para a VPS em `authorized_keys` | Chave privada SSH |
| Chave privada SSH | Permanece somente no computador local | Um arquivo a ser enviado para a VPS |

Nunca copie, envie ou registre no repositório a chave privada SSH, senhas ou outros dados reais de acesso.

## 1. Provisionar a VPS

1. Crie a VPS no painel da Contabo.
2. Anote o IP público atribuído à VPS. Neste documento, ele será representado por `IP_PUBLICO_DA_VPS`.
3. Aguarde a conclusão do provisionamento antes de tentar a primeira conexão.

## 2. Configurar e abrir a console VNC

No painel da Contabo, localize a console VNC da VPS e configure ou obtenha a senha VNC. Os nomes exatos das opções podem variar no painel, mas a conexão deve fornecer um host/IP e, quando aplicável, uma porta VNC.

No computador Linux, instale o Remmina em distribuições baseadas em Debian ou Ubuntu:

```bash
sudo apt update
sudo apt install remmina remmina-plugin-vnc
```

No Remmina, crie uma conexão com estes valores:

- **Protocolo:** `VNC`
- **Servidor:** `IP_PUBLICO_DA_VPS` ou `IP_PUBLICO_DA_VPS:PORTA_VNC`, conforme informado pela Contabo
- **Senha:** a senha VNC configurada no painel

A senha solicitada pelo Remmina protege o acesso à console. Ela não é a senha do usuário `root`.

## 3. Definir a senha root e entrar na VPS

Defina ou redefina a senha do usuário `root` no painel da Contabo. Em seguida, abra a conexão VNC no Remmina.

Na tela de login do sistema operacional dentro da console, informe:

```text
login: root
Password: <senha-root-da-vps>
```

Se receber `Login incorrect` após redefinir a senha, reinicie a VPS pelo painel, aguarde alguns minutos e digite a senha manualmente. Layouts de teclado na VNC podem trocar símbolos; durante a recuperação, uma senha temporária composta apenas de letras e números reduz esse risco.

## 4. Gerar uma chave SSH no computador local

No computador local, verifique primeiro se já existe uma chave pública:

```bash
ls ~/.ssh/id_ed25519.pub
```

Caso ela não exista, gere uma chave ED25519:

```bash
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"
```

Aceite o caminho padrão (`~/.ssh/id_ed25519`) ou escolha outro caminho local. Defina uma passphrase para proteger a chave privada.

## 5. Copiar a chave pública com ssh-copy-id

Confirme que a VPS está acessível por SSH na porta configurada (normalmente `22`) e que o login de `root` por senha está temporariamente habilitado. Então execute no computador local:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@IP_PUBLICO_DA_VPS
```

O comando pede a senha de `root` uma vez e adiciona apenas o conteúdo de `id_ed25519.pub` ao arquivo `/root/.ssh/authorized_keys` da VPS.

Teste o acesso por chave:

```bash
ssh -i ~/.ssh/id_ed25519 root@IP_PUBLICO_DA_VPS
```

Para uma chave RSA existente, substitua `id_ed25519` e `id_ed25519.pub` por `id_rsa` e `id_rsa.pub` nos comandos.

## 6. Quando a identidade SSH do host mudou

Após reinstalar ou recriar uma VPS, as chaves de identidade do servidor SSH podem ser alteradas. O cliente então pode mostrar a mensagem `REMOTE HOST IDENTIFICATION HAS CHANGED`.

Não remova a entrada antiga automaticamente. Pela console VNC, obtenha a fingerprint da chave ED25519 do servidor:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256
```

Compare o valor `SHA256:...` retornado com a fingerprint exibida pelo seu cliente SSH. Se forem idênticos e a recriação da VPS for esperada, remova apenas a entrada anterior desse IP no computador local:

```bash
ssh-keygen -R IP_PUBLICO_DA_VPS
```

Repita o `ssh-copy-id` ou a conexão `ssh` e confirme a nova fingerprint somente depois dessa comparação. Não use `StrictHostKeyChecking=no`, pois isso pode ocultar uma troca indevida de identidade do servidor.

## Solução rápida de problemas

| Situação | Ação inicial |
| --- | --- |
| Remmina pede uma senha antes de exibir o Linux | Use a senha VNC do painel Contabo. |
| A tela Linux retorna `Login incorrect` | Use `root`, redefina a senha no painel, reinicie a VPS e verifique o layout do teclado VNC. |
| `ssh-copy-id` informa que a identidade remota mudou | Valide a fingerprint pela VNC antes de executar `ssh-keygen -R`. |
| SSH não conecta | Confirme IP, porta SSH, firewall e que o serviço SSH está em execução pela console VNC. |

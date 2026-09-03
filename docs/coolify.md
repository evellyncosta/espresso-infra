# Coolify

Este documento descreve o papel do Coolify na infraestrutura do Espresso.

Voltar para o [README](../README.md). Consulte também [Aplicação Espresso API](application.md), [Arquitetura](architecture.md), [SigNoz](signoz.md) e [Operação](operations.md).

## Papel do Coolify

O Coolify é a plataforma de deploy e runtime dos containers da aplicação. Após o provisionamento base, ele é responsável por:

- integração com o repositório da aplicação;
- build e deploy;
- restart e lifecycle dos containers;
- variáveis de ambiente e secrets da aplicação;
- domínio, HTTP/HTTPS e certificados;
- container da aplicação Spring Espresso;
- PostgreSQL e Redis/Valkey quando esses serviços forem executados pelo Coolify;
- volumes persistentes dos serviços gerenciados.

O Taskfile não deve duplicar essas responsabilidades.

## Instalação

O provisionamento base instala ou preserva o Coolify:

```bash
task setup
```

Também é possível executar somente a task dedicada:

```bash
task install:coolify
```

O diretório esperado da instalação é configurado por `COOLIFY_EXPECTED_DIR` e usa `/data/coolify/source` por padrão.

## Acesso inicial

Após a instalação, o acesso inicial ao painel do Coolify fica disponível na porta `8000`:

```text
http://<SERVER_HOST>:8000
```

Depois de configurar domínio e HTTPS pelo proxy do Coolify, o acesso normal deve passar pelas portas `80` e `443`.

Para acessar a CLI da VPS:

```bash
ssh <SERVER_USER>@<SERVER_HOST>
```

Comandos úteis dentro da VPS:

```bash
sudo docker ps
cd /data/coolify/source
sudo docker exec -it coolify bash
```

O terminal web do Coolify é acessado pela interface do painel. Quando o painel é acessado diretamente por IP, ele depende da porta `6002/tcp`.

## Portas diretas

| Porta | Uso |
| --- | --- |
| `8000/tcp` | Acesso direto inicial ao dashboard do Coolify. |
| `6001/tcp` | Atualizações em tempo real do dashboard quando acessado por IP direto. |
| `6002/tcp` | Terminal web por IP direto. |

Depois que o dashboard estiver configurado por domínio/proxy no Coolify, as portas diretas `8000`, `6001` e `6002` podem ser restringidas ou fechadas conforme a política operacional do ambiente.

## Relação com SigNoz

SigNoz não é gerenciado pelo Coolify nesta infraestrutura. Ele é provisionado separadamente via Foundry/foundryctl, conforme [SigNoz](signoz.md).

O collector PostgreSQL também não pertence ao Compose do Coolify. Ele se conecta à rede Docker `coolify` para alcançar o PostgreSQL da aplicação sem publicar a porta `5432` no host. Veja [Collector PostgreSQL](postgres-collector.md).

# Espresso Infra

Provisionamento base da VPS Espresso com Taskfile, Docker e Coolify. A VPS já deve existir e aceitar acesso SSH; este repositório não cria recursos no provedor.

Observabilidade é operada separadamente em [espresso-observability](https://github.com/evellyncosta/espresso-observability). Este repositório não instala, consulta ou destrói SigNoz ou o collector PostgreSQL.

```bash
cp .env.example .env
task setup
```

## Documentação

- [Arquitetura](docs/architecture.md)
- [Aplicação Espresso API](docs/application.md)
- [Coolify](docs/coolify.md)
- [Operação](docs/operations.md)
- [ADRs](docs/adrs/README.md)

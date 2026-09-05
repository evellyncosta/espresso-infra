# Operação

Voltar para o [README](../README.md).

Crie `.env` a partir de `.env.example` e informe `SERVER_HOST`, `SERVER_USER` e `SSH_KEY_PATH`.

```bash
task setup
task status
```

O fluxo instala ou preserva sistema, Docker, UFW e Coolify. Para observabilidade, incluindo SigNoz, collector PostgreSQL, firewall específico, status e destruição, use [espresso-observability](https://github.com/evellyncosta/espresso-observability).

# Arquitetura

Voltar para o [README](../README.md).

O Espresso Infra prepara a VPS, Docker, UFW e Coolify. O Coolify gerencia a aplicação Espresso API, PostgreSQL, Redis/Valkey, domínios e certificados.

SigNoz e o collector PostgreSQL pertencem ao [espresso-observability](https://github.com/evellyncosta/espresso-observability). Esse repositório consome SSH, Docker/Compose e, para o collector, a rede Docker e PostgreSQL já providos pelo Coolify; não altera o lifecycle desses componentes.

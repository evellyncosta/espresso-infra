# Espresso Infra

Repositório responsável por provisionar e manter um banco de dados PostgreSQL no Amazon RDS e a infraestrutura AWS necessária para sua operação.

O escopo inclui os recursos de rede, segurança e serviços de suporte associados ao banco de dados.

Também provisiona a execução privada da Espresso API no Amazon ECS Express Mode sobre Fargate:

- repository privado no Amazon ECR;
- ECS Express Gateway Service com ALB interno;
- acesso da task ao RDS pela porta 5432;
- segredo do RDS injetado pelo AWS Secrets Manager;
- logs da aplicação no CloudWatch;
- VPC Endpoints para execução sem NAT Gateway.

Os parâmetros `ecrRepositoryName`, `applicationImage`, `applicationCpu`, `applicationMemory`,
`applicationHealthCheckPath`, `applicationMinTasks` e `applicationMaxTasks`
podem ser definidos no Pulumi Config. Se `applicationImage` não for informado,
será usada a imagem `latest` do repository criado no ECR; publique essa imagem
antes de iniciar o serviço.

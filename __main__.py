"""Infraestrutura AWS do banco PostgreSQL do Espresso."""

import json

import pulumi
import pulumi_aws as aws
import pulumi_random as random


config = pulumi.Config()
stack = pulumi.get_stack()

project_name = config.get("projectName") or "espresso"
environment = config.get("environment") or stack
owner = config.get("owner") or "espresso"
name = f"{project_name}-{environment}"

vpc_cidr = config.get("vpcCidr") or "10.40.0.0/16"
availability_zones = config.get_object("availabilityZones") or []
private_subnet_cidrs = config.get_object("privateSubnetCidrs") or [
    "10.40.10.0/24",
    "10.40.11.0/24",
]
vpn_subnet_cidrs = config.get_object("vpnSubnetCidrs") or [
    "10.40.20.0/24",
    "10.40.21.0/24",
]

if len(availability_zones) == 0:
    availability_zones = aws.get_availability_zones(state="available").names[:2]

if len(availability_zones) < 2:
    raise ValueError("O RDS requer pelo menos duas Availability Zones.")

if len(private_subnet_cidrs) < len(availability_zones):
    raise ValueError("Informe uma privateSubnetCidrs para cada Availability Zone.")

if len(vpn_subnet_cidrs) < len(availability_zones):
    raise ValueError("Informe uma vpnSubnetCidrs para cada Availability Zone.")

allowed_security_group_ids = config.get_object("allowedSecurityGroupIds") or []
allowed_cidr_blocks = config.get_object("allowedCidrBlocks") or []
client_vpn_client_cidr = config.get("clientVpnClientCidr") or "10.42.0.0/22"
client_vpn_server_certificate_arn = config.get("clientVpnServerCertificateArn")
client_vpn_client_certificate_arn = config.get("clientVpnClientCertificateArn")
application_image = config.get("applicationImage")
ecr_repository_name = config.get("ecrRepositoryName") or f"{project_name}-api"
application_cpu = config.get("applicationCpu") or "1024"
application_memory = config.get("applicationMemory") or "2048"
application_container_port = config.get_int("applicationContainerPort") or 8080
application_health_check_path = config.get("applicationHealthCheckPath") or "/"
application_min_tasks = config.get_int("applicationMinTasks")
if application_min_tasks is None:
    application_min_tasks = 1
application_max_tasks = config.get_int("applicationMaxTasks")
if application_max_tasks is None:
    application_max_tasks = 1
if application_min_tasks < 1 or application_max_tasks < application_min_tasks:
    raise ValueError(
        "applicationMinTasks deve ser pelo menos 1 e não pode exceder applicationMaxTasks."
    )

if not client_vpn_server_certificate_arn or not client_vpn_client_certificate_arn:
    raise ValueError(
        "Configure clientVpnServerCertificateArn e clientVpnClientCertificateArn "
        "antes do preview."
    )

database_name = config.get("databaseName") or "espresso"
master_username = config.get("masterUsername") or "espresso_admin"
engine_version = config.get("engineVersion") or "16.14"
parameter_group_family = config.get("parameterGroupFamily") or "postgres16"
instance_class = config.get("instanceClass") or "db.t4g.medium"
allocated_storage = config.get_int("allocatedStorage") or 100
max_allocated_storage = config.get_int("maxAllocatedStorage") or 1000
multi_az = config.get_bool("multiAz") or False
backup_retention_period = config.get_int("backupRetentionPeriod") or 7
backup_window = config.get("backupWindow") or "03:00-03:30"
maintenance_window = config.get("maintenanceWindow") or "sun:04:00-sun:04:30"
performance_insights_enabled = config.get_bool("performanceInsightsEnabled")
if performance_insights_enabled is None:
    performance_insights_enabled = True
monitoring_interval = config.get_int("monitoringInterval")
if monitoring_interval is None:
    monitoring_interval = 60
log_retention_in_days = config.get_int("logRetentionInDays") or 7
kms_key_arn = config.get("kmsKeyArn")
deletion_protection = config.get_bool("deletionProtection")
if deletion_protection is None:
    deletion_protection = False
skip_final_snapshot = config.get_bool("skipFinalSnapshot")
if skip_final_snapshot is None:
    skip_final_snapshot = True

tags = {
    "Project": project_name,
    "Environment": environment,
    "Owner": owner,
    "ManagedBy": "pulumi",
}

vpc = aws.ec2.Vpc(
    "vpc",
    cidr_block=vpc_cidr,
    enable_dns_hostnames=True,
    enable_dns_support=True,
    tags={**tags, "Name": f"{name}-vpc"},
)

private_subnets = []
for index, availability_zone in enumerate(availability_zones):
    private_subnets.append(
        aws.ec2.Subnet(
            f"private-subnet-{index + 1}",
            vpc_id=vpc.id,
            availability_zone=availability_zone,
            cidr_block=private_subnet_cidrs[index],
            tags={
                **tags,
                "Name": f"{name}-private-{availability_zone}",
                "Tier": "private",
            },
        )
    )

private_route_table = aws.ec2.RouteTable(
    "private-route-table",
    vpc_id=vpc.id,
    tags={**tags, "Name": f"{name}-private"},
)

for index, subnet in enumerate(private_subnets):
    aws.ec2.RouteTableAssociation(
        f"private-route-table-association-{index + 1}",
        route_table_id=private_route_table.id,
        subnet_id=subnet.id,
    )

db_subnet_group = aws.rds.SubnetGroup(
    "db-subnet-group",
    name=f"{name}-db-subnet-group",
    description=f"Private subnets for the {name} PostgreSQL RDS instance",
    subnet_ids=[subnet.id for subnet in private_subnets],
    tags={**tags, "Name": f"{name}-db-subnet-group"},
)

database_security_group = aws.ec2.SecurityGroup(
    "database-security-group",
    name=f"{name}-database",
    description=f"Ingress control for the {name} PostgreSQL database",
    vpc_id=vpc.id,
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
            description="Allow RDS managed service egress",
        )
    ],
    tags={**tags, "Name": f"{name}-database"},
)

client_vpn_security_group = aws.ec2.SecurityGroup(
    "client-vpn-security-group",
    name=f"{name}-client-vpn",
    description=f"Security group for the {name} AWS Client VPN endpoint",
    vpc_id=vpc.id,
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
            description="Allow VPN client traffic to private resources",
        )
    ],
    tags={**tags, "Name": f"{name}-client-vpn"},
)

aws.ec2.SecurityGroupRule(
    "database-ingress-client-vpn",
    type="ingress",
    security_group_id=database_security_group.id,
    source_security_group_id=client_vpn_security_group.id,
    protocol="tcp",
    from_port=5432,
    to_port=5432,
    description="PostgreSQL access from the Client VPN",
)

for index, source_security_group_id in enumerate(allowed_security_group_ids):
    aws.ec2.SecurityGroupRule(
        f"database-ingress-security-group-{index + 1}",
        type="ingress",
        security_group_id=database_security_group.id,
        source_security_group_id=source_security_group_id,
        protocol="tcp",
        from_port=5432,
        to_port=5432,
        description="PostgreSQL access from an approved security group",
    )

for index, cidr_block in enumerate(allowed_cidr_blocks):
    aws.ec2.SecurityGroupRule(
        f"database-ingress-cidr-{index + 1}",
        type="ingress",
        security_group_id=database_security_group.id,
        cidr_blocks=[cidr_block],
        protocol="tcp",
        from_port=5432,
        to_port=5432,
        description="PostgreSQL access from an approved private network",
    )

application_security_group = aws.ec2.SecurityGroup(
    "application-security-group",
    name=f"{name}-application",
    description=f"Security group for the {name} Espresso API",
    vpc_id=vpc.id,
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
            description="Allow application traffic to private AWS services",
        )
    ],
    tags={**tags, "Name": f"{name}-application"},
)

aws.ec2.SecurityGroupRule(
    "application-ingress-client-vpn",
    type="ingress",
    security_group_id=application_security_group.id,
    source_security_group_id=client_vpn_security_group.id,
    protocol="tcp",
    from_port=443,
    to_port=443,
    description="HTTPS access from the Client VPN",
)

aws.ec2.SecurityGroupRule(
    "database-ingress-application",
    type="ingress",
    security_group_id=database_security_group.id,
    source_security_group_id=application_security_group.id,
    protocol="tcp",
    from_port=5432,
    to_port=5432,
    description="PostgreSQL access from the ECS application",
)

endpoint_security_group = aws.ec2.SecurityGroup(
    "vpc-endpoint-security-group",
    name=f"{name}-vpc-endpoints",
    description=f"Private AWS service endpoints for the {name} application",
    vpc_id=vpc.id,
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
            description="Allow endpoint responses",
        )
    ],
    tags={**tags, "Name": f"{name}-vpc-endpoints"},
)

aws.ec2.SecurityGroupRule(
    "vpc-endpoint-ingress-https",
    type="ingress",
    security_group_id=endpoint_security_group.id,
    source_security_group_id=application_security_group.id,
    protocol="tcp",
    from_port=443,
    to_port=443,
    description="HTTPS from ECS tasks",
)

aws_region = aws.get_region().region
for endpoint_name in ["ecr.api", "ecr.dkr", "secretsmanager", "logs"]:
    aws.ec2.VpcEndpoint(
        f"{endpoint_name.replace('.', '-')}-endpoint",
        vpc_id=vpc.id,
        service_name=f"com.amazonaws.{aws_region}.{endpoint_name}",
        vpc_endpoint_type="Interface",
        private_dns_enabled=True,
        subnet_ids=[subnet.id for subnet in private_subnets],
        security_group_ids=[endpoint_security_group.id],
        tags={**tags, "Name": f"{name}-{endpoint_name.replace('.', '-')}"},
    )

aws.ec2.VpcEndpoint(
    "s3-endpoint",
    vpc_id=vpc.id,
    service_name=f"com.amazonaws.{aws_region}.s3",
    vpc_endpoint_type="Gateway",
    route_table_ids=[private_route_table.id],
    tags={**tags, "Name": f"{name}-s3"},
)

vpn_subnets = []
for index, availability_zone in enumerate(availability_zones):
    vpn_subnets.append(
        aws.ec2.Subnet(
            f"client-vpn-subnet-{index + 1}",
            vpc_id=vpc.id,
            availability_zone=availability_zone,
            cidr_block=vpn_subnet_cidrs[index],
            tags={
                **tags,
                "Name": f"{name}-client-vpn-{availability_zone}",
                "Tier": "vpn",
            },
        )
    )

client_vpn_endpoint = aws.ec2clientvpn.Endpoint(
    "client-vpn-endpoint",
    description=f"Private access to the {name} VPC",
    vpc_id=vpc.id,
    client_cidr_block=client_vpn_client_cidr,
    server_certificate_arn=client_vpn_server_certificate_arn,
    authentication_options=[
        aws.ec2clientvpn.EndpointAuthenticationOptionArgs(
            type="certificate-authentication",
            root_certificate_chain_arn=client_vpn_client_certificate_arn,
        )
    ],
    split_tunnel=True,
    transport_protocol="udp",
    security_group_ids=[client_vpn_security_group.id],
    connection_log_options=aws.ec2clientvpn.EndpointConnectionLogOptionsArgs(
        enabled=False,
    ),
    tags={**tags, "Name": f"{name}-client-vpn"},
)

vpn_associations = []
for index, vpn_subnet in enumerate(vpn_subnets):
    vpn_associations.append(
        aws.ec2clientvpn.NetworkAssociation(
            f"client-vpn-network-association-{index + 1}",
            client_vpn_endpoint_id=client_vpn_endpoint.id,
            subnet_id=vpn_subnet.id,
        )
    )

aws.ec2clientvpn.AuthorizationRule(
    "client-vpn-vpc-authorization",
    client_vpn_endpoint_id=client_vpn_endpoint.id,
    target_network_cidr=vpc_cidr,
    authorize_all_groups=True,
    description="Allow authenticated VPN clients to access the Espresso VPC",
    opts=pulumi.ResourceOptions(depends_on=vpn_associations),
)

monitoring_assume_role_policy = json.dumps(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "monitoring.rds.amazonaws.com"},
                "Action": "sts:AssumeRole",
            }
        ],
    }
)

enhanced_monitoring_role = aws.iam.Role(
    "enhanced-monitoring-role",
    name=f"{name}-rds-monitoring",
    assume_role_policy=monitoring_assume_role_policy,
    tags=tags,
)

aws.iam.RolePolicyAttachment(
    "enhanced-monitoring-policy",
    role=enhanced_monitoring_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole",
)

postgresql_log_group = aws.cloudwatch.LogGroup(
    "postgresql-log-group",
    name=f"/aws/rds/instance/{name}/postgresql",
    retention_in_days=log_retention_in_days,
    tags=tags,
)

upgrade_log_group = aws.cloudwatch.LogGroup(
    "upgrade-log-group",
    name=f"/aws/rds/instance/{name}/upgrade",
    retention_in_days=log_retention_in_days,
    tags=tags,
)

parameter_group = aws.rds.ParameterGroup(
    "postgres-parameter-group",
    name=f"{name}-postgres",
    family=parameter_group_family,
    description=f"PostgreSQL parameters for {name}",
    parameters=[
        aws.rds.ParameterGroupParameterArgs(
            name="rds.force_ssl",
            value="1",
            apply_method="pending-reboot",
        ),
        aws.rds.ParameterGroupParameterArgs(
            name="log_min_duration_statement",
            value="1000",
            apply_method="immediate",
        ),
    ],
    tags={**tags, "Name": f"{name}-postgres"},
)

final_snapshot_id = random.RandomId(
    "final-snapshot-id",
    byte_length=4,
)

database = aws.rds.Instance(
    "postgresql",
    identifier=name,
    engine="postgres",
    engine_version=engine_version,
    instance_class=instance_class,
    port=5432,
    db_name=database_name,
    username=master_username,
    manage_master_user_password=True,
    kms_key_id=kms_key_arn,
    allocated_storage=allocated_storage,
    max_allocated_storage=max_allocated_storage,
    storage_type="gp3",
    storage_encrypted=True,
    db_subnet_group_name=db_subnet_group.name,
    vpc_security_group_ids=[database_security_group.id],
    publicly_accessible=False,
    parameter_group_name=parameter_group.name,
    multi_az=multi_az,
    auto_minor_version_upgrade=True,
    allow_major_version_upgrade=False,
    apply_immediately=False,
    deletion_protection=deletion_protection,
    copy_tags_to_snapshot=True,
    skip_final_snapshot=skip_final_snapshot,
    final_snapshot_identifier=None
    if skip_final_snapshot
    else final_snapshot_id.hex.apply(lambda value: f"{name}-final-{value}"),
    backup_retention_period=backup_retention_period,
    backup_window=backup_window,
    maintenance_window=maintenance_window,
    enabled_cloudwatch_logs_exports=["postgresql", "upgrade"],
    performance_insights_enabled=performance_insights_enabled,
    monitoring_interval=monitoring_interval,
    monitoring_role_arn=enhanced_monitoring_role.arn if monitoring_interval else None,
    tags={**tags, "Name": name},
    opts=pulumi.ResourceOptions(
        depends_on=[
            enhanced_monitoring_role,
            postgresql_log_group,
            upgrade_log_group,
        ]
    ),
)

ecr_repository = aws.ecr.Repository(
    "application-repository",
    name=ecr_repository_name,
    image_tag_mutability="MUTABLE",
    image_scanning_configuration=aws.ecr.RepositoryImageScanningConfigurationArgs(
        scan_on_push=True,
    ),
    force_delete=True,
    tags={**tags, "Name": f"{name}-api"},
)

application_log_group = aws.cloudwatch.LogGroup(
    "application-log-group",
    name=f"/aws/ecs/{name}/application",
    retention_in_days=log_retention_in_days,
    tags=tags,
)

def assume_role_policy(service: str) -> str:
    return json.dumps(
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": service},
                    "Action": "sts:AssumeRole",
                }
            ],
        }
    )


infrastructure_role = aws.iam.Role(
    "ecs-infrastructure-role",
    name=f"{name}-ecs-infrastructure",
    assume_role_policy=assume_role_policy("ecs.amazonaws.com"),
    tags=tags,
)
infrastructure_policy = aws.iam.RolePolicyAttachment(
    "ecs-infrastructure-policy",
    role=infrastructure_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices",
)

execution_role = aws.iam.Role(
    "ecs-execution-role",
    name=f"{name}-ecs-execution",
    assume_role_policy=assume_role_policy("ecs-tasks.amazonaws.com"),
    tags=tags,
)
execution_policy = aws.iam.RolePolicyAttachment(
    "ecs-execution-policy",
    role=execution_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
)

database_secret_arn = database.master_user_secrets.apply(
    lambda secrets: secrets[0].secret_arn if secrets else None
)
database_secret_policy = aws.iam.RolePolicy(
    "ecs-execution-database-secret-policy",
    role=execution_role.id,
    policy=database_secret_arn.apply(
        lambda secret_arn: json.dumps(
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "secretsmanager:DescribeSecret",
                            "secretsmanager:GetSecretValue",
                        ],
                        "Resource": secret_arn,
                    }
                ],
            }
        )
    ),
)

task_role = aws.iam.Role(
    "ecs-task-role",
    name=f"{name}-ecs-task",
    assume_role_policy=assume_role_policy("ecs-tasks.amazonaws.com"),
    tags=tags,
)

if application_image is None:
    application_image = ecr_repository.repository_url.apply(lambda url: f"{url}:latest")

ecs_cluster = aws.ecs.Cluster(
    "application-cluster",
    name=f"{name}-cluster",
    tags={**tags, "Name": f"{name}-cluster"},
)

ecs_service = aws.ecs.ExpressGatewayService(
    "application-service",
    service_name=f"{name}-api",
    cluster=ecs_cluster.name,
    cpu=application_cpu,
    memory=application_memory,
    execution_role_arn=execution_role.arn,
    infrastructure_role_arn=infrastructure_role.arn,
    task_role_arn=task_role.arn,
    health_check_path=application_health_check_path,
    network_configurations=[
        aws.ecs.ExpressGatewayServiceNetworkConfigurationArgs(
            subnets=[subnet.id for subnet in private_subnets],
            security_groups=[application_security_group.id],
        )
    ],
    scaling_targets=[
        aws.ecs.ExpressGatewayServiceScalingTargetArgs(
            auto_scaling_metric="AVERAGE_CPU",
            auto_scaling_target_value=70,
            min_task_count=application_min_tasks,
            max_task_count=application_max_tasks,
        )
    ],
    primary_container=aws.ecs.ExpressGatewayServicePrimaryContainerArgs(
        image=application_image,
        container_port=application_container_port,
        aws_logs_configurations=[
            aws.ecs.ExpressGatewayServicePrimaryContainerAwsLogsConfigurationArgs(
                log_group=application_log_group.name,
                log_stream_prefix="ecs",
            )
        ],
        environments=[
            aws.ecs.ExpressGatewayServicePrimaryContainerEnvironmentArgs(
                name="DB_HOST", value=database.address
            ),
            aws.ecs.ExpressGatewayServicePrimaryContainerEnvironmentArgs(
                name="DB_PORT", value="5432"
            ),
            aws.ecs.ExpressGatewayServicePrimaryContainerEnvironmentArgs(
                name="DB_NAME", value=database_name
            ),
            aws.ecs.ExpressGatewayServicePrimaryContainerEnvironmentArgs(
                name="DB_USER", value=master_username
            ),
        ],
        secrets=[
            aws.ecs.ExpressGatewayServicePrimaryContainerSecretArgs(
                name="DB_PASSWORD",
                value_from=database_secret_arn.apply(
                    lambda arn: f"{arn}:password::"
                ),
            )
        ],
    ),
    wait_for_steady_state=False,
    tags={**tags, "Name": f"{name}-api"},
    opts=pulumi.ResourceOptions(
        depends_on=[
            infrastructure_policy,
            execution_policy,
            database_secret_policy,
            application_log_group,
            ecr_repository,
            ecs_cluster,
        ]
    ),
)

if not skip_final_snapshot and not deletion_protection:
    raise ValueError(
        "Mantenha deletionProtection habilitado ou defina skipFinalSnapshot=true "
        "em ambientes descartáveis."
    )

pulumi.export("vpc_id", vpc.id)
pulumi.export("database_identifier", database.identifier)
pulumi.export("database_endpoint", database.address)
pulumi.export("database_port", database.port)
pulumi.export("database_security_group_id", database_security_group.id)
pulumi.export("client_vpn_endpoint_id", client_vpn_endpoint.id)
pulumi.export(
    "master_user_secret_arn",
    database_secret_arn,
)
pulumi.export("ecr_repository_url", ecr_repository.repository_url)
pulumi.export("ecs_service_name", ecs_service.service_name)
pulumi.export("ecs_cluster_name", ecs_cluster.name)
pulumi.export(
    "application_endpoint",
    ecs_service.ingress_paths.apply(
        lambda paths: paths[0].endpoint if paths else None
    ),
)

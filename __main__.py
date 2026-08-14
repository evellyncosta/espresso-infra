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
log_retention_in_days = config.get_int("logRetentionInDays") or 30
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
    database.master_user_secrets.apply(
        lambda secrets: secrets[0].secret_arn if secrets else None
    ),
)

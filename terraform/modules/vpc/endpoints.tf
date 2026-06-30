locals {
  gateway_vpc_endpoints = {
    s3 = {
      service      = "s3"
      policy       = null
      service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
    }
    dynamodb = {
      service      = "dynamodb"
      policy       = null
      service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
    }
  }

  interface_vpc_endpoints = {
    ecr_api = {
      service               = "ecr.api"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    ecr_dkr = {
      service               = "ecr.dkr"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    secretsmanager = {
      service               = "secretsmanager"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    ssm = {
      service               = "ssm"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ssm"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    ssmmessages = {
      service               = "ssmmessages"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    ec2 = {
      service               = "ec2"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ec2"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    ec2messages = {
      service               = "ec2messages"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    kms = {
      service               = "kms"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.kms"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
    logs = {
      service               = "logs"
      service_name          = "com.amazonaws.${data.aws_region.current.name}.logs"
      private_dns_enabled   = true
      policy                = null
      subnet_ids            = aws_subnet.private[*].id
      security_group_ids    = var.vpc_endpoint_security_group_ids
    }
  }
}

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints && var.s3_vpc_endpoint_enabled ? 1 : 0

  vpc_id       = local.vpc_id
  service_name = local.gateway_vpc_endpoints.s3.service_name

  route_table_ids = concat(
    aws_route_table.private[*].id,
    aws_route_table.public[*].id
  )

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints && var.dynamodb_vpc_endpoint_enabled ? 1 : 0

  vpc_id       = local.vpc_id
  service_name = local.gateway_vpc_endpoints.dynamodb.service_name

  route_table_ids = concat(
    aws_route_table.private[*].id,
    aws_route_table.public[*].id
  )

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-dynamodb-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints && var.ecr_api_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ecr_api.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ecr_api.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ecr_api.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ecr_api.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ecr-api-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints && var.ecr_dkr_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ecr_dkr.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ecr_dkr.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ecr_dkr.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ecr_dkr.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ecr-dkr-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.enable_vpc_endpoints && var.secretsmanager_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.secretsmanager.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.secretsmanager.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.secretsmanager.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.secretsmanager.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-secretsmanager-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_vpc_endpoints && var.ssm_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ssm.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ssm.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ssm.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ssm.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ssm-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.enable_vpc_endpoints && var.ssmmessages_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ssmmessages.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ssmmessages.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ssmmessages.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ssmmessages.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ssmmessages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_vpc_endpoints && var.ec2_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ec2.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ec2.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ec2.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ec2.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ec2-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  count = var.enable_vpc_endpoints && var.ec2messages_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.ec2messages.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.ec2messages.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.ec2messages.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.ec2messages.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-ec2messages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "kms" {
  count = var.enable_vpc_endpoints && var.kms_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.kms.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.kms.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.kms.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.kms.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-kms-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints && var.logs_endpoint_enabled ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = local.interface_vpc_endpoints.logs.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = local.interface_vpc_endpoints.logs.private_dns_enabled
  subnet_ids          = local.interface_vpc_endpoints.logs.subnet_ids
  security_group_ids  = local.interface_vpc_endpoints.logs.security_group_ids

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-logs-endpoint"
    }
  )
}

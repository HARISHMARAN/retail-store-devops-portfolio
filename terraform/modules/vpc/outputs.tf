output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = var.cidr
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this[0].arn
}

output "vpc_owner_id" {
  description = "The ID of the account that owns the VPC"
  value       = aws_vpc.this[0].owner_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = element(concat(aws_db_subnet_group.database[*].id, [""]), 0)
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = element(concat(aws_db_subnet_group.database[*].name, [""]), 0)
}

output "nat_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = concat(aws_nat_gateway.this[*].id, aws_nat_gateway.az_reuse[*].id)
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this[0].id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = aws_internet_gateway.this[0].arn
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = element(concat(aws_vpn_gateway.this[*].id, [""]), 0)
}

output "vgw_arn" {
  description = "The ARN of the VPN Gateway"
  value       = element(concat(aws_vpn_gateway.this[*].arn, [""]), 0)
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = aws_route_table.database[*].id
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = element(concat(aws_network_acl.public[*].id, [""]), 0)
}

output "private_network_acl_ids" {
  description = "List of IDs of private network ACLs"
  value       = aws_network_acl.private[*].id
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = element(concat(aws_network_acl.database[*].id, [""]), 0)
}

output "azs" {
  description = "A list of availability zones used"
  value       = local.azs
}

output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = element(concat(aws_vpc_endpoint.s3[*].id, [""]), 0)
}

output "vpc_endpoint_s3_arn" {
  value = element(concat(aws_vpc_endpoint.s3[*].arn, [""]), 0)
}

output "vpc_endpoint_dynamodb_id" {
  description = "The ID of VPC endpoint for DynamoDB"
  value       = element(concat(aws_vpc_endpoint.dynamodb[*].id, [""]), 0)
}

output "vpc_endpoint_dynamodb_arn" {
  value = element(concat(aws_vpc_endpoint.dynamodb[*].arn, [""]), 0)
}

output "vpc_endpoint_ecr_api_id" {
  value = element(concat(aws_vpc_endpoint.ecr_api[*].id, [""]), 0)
}

output "vpc_endpoint_ecr_api_arn" {
  value = element(concat(aws_vpc_endpoint.ecr_api[*].arn, [""]), 0)
}

output "vpc_endpoint_ecr_dkr_id" {
  value = element(concat(aws_vpc_endpoint.ecr_dkr[*].id, [""]), 0)
}

output "vpc_endpoint_ecr_dkr_arn" {
  value = element(concat(aws_vpc_endpoint.ecr_dkr[*].arn, [""]), 0)
}

output "vpc_endpoint_secretsmanager_id" {
  value = element(concat(aws_vpc_endpoint.secretsmanager[*].id, [""]), 0)
}

output "vpc_endpoint_secretsmanager_arn" {
  value = element(concat(aws_vpc_endpoint.secretsmanager[*].arn, [""]), 0)
}

output "vpc_endpoint_ssm_id" {
  value = element(concat(aws_vpc_endpoint.ssm[*].id, [""]), 0)
}

output "vpc_endpoint_ssm_arn" {
  value = element(concat(aws_vpc_endpoint.ssm[*].arn, [""]), 0)
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = element(concat(aws_flow_log.this[*].id, [""]), 0)
}

output "flow_log_arn" {
  value = element(concat(aws_flow_log.this[*].arn, [""]), 0)
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for VPC Flow Logs"
  value       = element(concat(aws_cloudwatch_log_group.flow_log[*].arn, [""]), 0)
}

output "flow_log_iam_role_arn" {
  value = element(concat(aws_iam_role.vpc_flow_log[*].arn, [""]), 0)
}

output "dhcp_options_id" {
  description = "The ID of the DHCP options set"
  value       = element(concat(aws_vpc_dhcp_options.this[*].id, [""]), 0)
}

output "dhcp_options_association_id" {
  description = "The ID of the DHCP options association"
  value       = element(concat(aws_vpc_dhcp_options_association.this[*].id, [""]), 0)
}

output "eip_ids" {
  description = "List of allocation IDs for the EIPs used by the NAT Gateways"
  value       = aws_eip.nat[*].id
}

output "eip_public_ips" {
  description = "List of public IPs for the EIPs used by the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "vpc_endpoints" {
  description = "A map of VPC endpoints created"
  value = {
    s3             = element(concat(aws_vpc_endpoint.s3[*].id, [""]), 0)
    dynamodb       = element(concat(aws_vpc_endpoint.dynamodb[*].id, [""]), 0)
    ecr_api        = element(concat(aws_vpc_endpoint.ecr_api[*].id, [""]), 0)
    ecr_dkr        = element(concat(aws_vpc_endpoint.ecr_dkr[*].id, [""]), 0)
    secretsmanager = element(concat(aws_vpc_endpoint.secretsmanager[*].id, [""]), 0)
    ssm            = element(concat(aws_vpc_endpoint.ssm[*].id, [""]), 0)
    ssmmessages    = element(concat(aws_vpc_endpoint.ssmmessages[*].id, [""]), 0)
    ec2            = element(concat(aws_vpc_endpoint.ec2[*].id, [""]), 0)
    ec2messages    = element(concat(aws_vpc_endpoint.ec2messages[*].id, [""]), 0)
    kms            = element(concat(aws_vpc_endpoint.kms[*].id, [""]), 0)
    logs           = element(concat(aws_vpc_endpoint.logs[*].id, [""]), 0)
  }
}

output "vpc_endpoint_ids" {
  description = "IDs of all VPC endpoints"
  value = merge(
    {
      s3             = element(concat(aws_vpc_endpoint.s3[*].id, [""]), 0)
      dynamodb       = element(concat(aws_vpc_endpoint.dynamodb[*].id, [""]), 0)
      ecr_api        = element(concat(aws_vpc_endpoint.ecr_api[*].id, [""]), 0)
      ecr_dkr        = element(concat(aws_vpc_endpoint.ecr_dkr[*].id, [""]), 0)
      secretsmanager = element(concat(aws_vpc_endpoint.secretsmanager[*].id, [""]), 0)
      ssm            = element(concat(aws_vpc_endpoint.ssm[*].id, [""]), 0)
      ssmmessages    = element(concat(aws_vpc_endpoint.ssmmessages[*].id, [""]), 0)
      ec2            = element(concat(aws_vpc_endpoint.ec2[*].id, [""]), 0)
      ec2messages    = element(concat(aws_vpc_endpoint.ec2messages[*].id, [""]), 0)
      kms            = element(concat(aws_vpc_endpoint.kms[*].id, [""]), 0)
      logs           = element(concat(aws_vpc_endpoint.logs[*].id, [""]), 0)
    }
  )
}

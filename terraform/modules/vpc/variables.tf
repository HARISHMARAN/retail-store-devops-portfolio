variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Should be true if you want to create a VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_az" {
  description = "The Availability Zone for the VPN Gateway"
  type        = string
  default     = null
}

variable "enable_flow_log" {
  description = "Should be true to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_destination_arn" {
  description = "The ARN of the CloudWatch log group or S3 bucket where VPC Flow Logs will be sent"
  type        = string
  default     = ""
}

variable "flow_log_log_format" {
  description = "The fields to include in the flow log record"
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"
}

variable "create_flow_log_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "The name of CloudWatch log group for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events"
  type        = number
  default     = 90
}

variable "enable_vpc_endpoints" {
  description = "Should be true to enable VPC endpoints"
  type        = bool
  default     = true
}

variable "vpc_endpoint_type" {
  description = "VPC endpoint type. Gateway or Interface"
  type        = string
  default     = "Interface"
}

variable "vpc_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface"
  type        = list(string)
  default     = []
}

variable "s3_vpc_endpoint_enabled" {
  description = "Should be true to enable S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "dynamodb_vpc_endpoint_enabled" {
  description = "Should be true to enable DynamoDB VPC endpoint"
  type        = bool
  default     = true
}

variable "ecr_api_endpoint_enabled" {
  description = "Should be true to create ecr api VPC endpoint"
  type        = bool
  default     = true
}

variable "ecr_dkr_endpoint_enabled" {
  description = "Should be true to create ecr dkr VPC endpoint"
  type        = bool
  default     = true
}

variable "secretsmanager_endpoint_enabled" {
  description = "Should be true to create secrets manager VPC endpoint"
  type        = bool
  default     = true
}

variable "ssm_endpoint_enabled" {
  description = "Should be true to create SSM VPC endpoint"
  type        = bool
  default     = true
}

variable "ssmmessages_endpoint_enabled" {
  description = "Should be true to create SSM messages VPC endpoint"
  type        = bool
  default     = true
}

variable "ec2_endpoint_enabled" {
  description = "Should be true to create EC2 VPC endpoint"
  type        = bool
  default     = true
}

variable "ec2messages_endpoint_enabled" {
  description = "Should be true to create EC2 messages VPC endpoint"
  type        = bool
  default     = true
}

variable "kms_endpoint_enabled" {
  description = "Should be true to create KMS VPC endpoint"
  type        = bool
  default     = true
}

variable "logs_endpoint_enabled" {
  description = "Should be true to create CloudWatch Logs VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_dhcp_options" {
  description = "Should be true to create DHCP options"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "Specify a list of NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "enable_network_acls" {
  description = "Should be true to enable custom network ACLs"
  type        = bool
  default     = true
}

variable "public_inbound_acl_rules" {
  description = "Public subnets inbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 80
      to_port    = 80
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no    = 110
      action     = "allow"
      from_port  = 443
      to_port    = 443
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no    = 120
      action     = "allow"
      from_port  = 1024
      to_port    = 65535
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    }
  ]
}

variable "public_outbound_acl_rules" {
  description = "Public subnets outbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]
}

variable "private_inbound_acl_rules" {
  description = "Private subnets inbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "10.0.0.0/8"
    }
  ]
}

variable "private_outbound_acl_rules" {
  description = "Private subnets outbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]
}

variable "database_inbound_acl_rules" {
  description = "Database subnets inbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 3306
      to_port    = 3306
      protocol   = "tcp"
      cidr_block = "10.0.0.0/16"
    },
    {
      rule_no    = 110
      action     = "allow"
      from_port  = 5432
      to_port    = 5432
      protocol   = "tcp"
      cidr_block = "10.0.0.0/16"
    }
  ]
}

variable "database_outbound_acl_rules" {
  description = "Database subnets outbound rules for network ACLs"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "10.0.0.0/16"
    }
  ]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for the internet gateway"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for the database subnets"
  type        = map(string)
  default     = {}
}

variable "public_route_table_tags" {
  description = "Additional tags for the public route tables"
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for the private route tables"
  type        = map(string)
  default     = {}
}

variable "database_route_table_tags" {
  description = "Additional tags for the database route tables"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for the NAT gateways"
  type        = map(string)
  default     = {}
}

variable "az_reuse_nat_gateway_ips" {
  description = "Should be true if you want to reuse NAT Gateway Elastic IPs across AZs"
  type        = bool
  default     = false
}

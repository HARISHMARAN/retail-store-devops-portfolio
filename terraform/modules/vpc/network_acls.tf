resource "aws_network_acl" "public" {
  count = var.enable_network_acls && length(aws_subnet.public) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-public-nacl"
    }
  )

  dynamic "ingress" {
    for_each = var.public_inbound_acl_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      protocol   = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = var.public_outbound_acl_rules
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      protocol   = egress.value.protocol
      cidr_block = egress.value.cidr_block
    }
  }
}

resource "aws_network_acl" "private" {
  count = var.enable_network_acls && length(aws_subnet.private) > 0 ? local.max_azs : 0

  vpc_id     = local.vpc_id
  subnet_ids = [element(aws_subnet.private, count.index).id]

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-private-nacl-${element(local.azs, count.index)}"
    }
  )

  dynamic "ingress" {
    for_each = var.private_inbound_acl_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      protocol   = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = var.private_outbound_acl_rules
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      protocol   = egress.value.protocol
      cidr_block = egress.value.cidr_block
    }
  }
}

resource "aws_network_acl" "database" {
  count = var.enable_network_acls && length(aws_subnet.database) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-database-nacl"
    }
  )

  dynamic "ingress" {
    for_each = var.database_inbound_acl_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      protocol   = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = var.database_outbound_acl_rules
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      protocol   = egress.value.protocol
      cidr_block = egress.value.cidr_block
    }
  }
}

resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

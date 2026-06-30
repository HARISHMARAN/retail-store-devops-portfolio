resource "aws_security_group" "rds" {
  count = var.create_rds_security_group ? 1 : 0

  name        = "${var.name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.security_group_tags,
    {
      Name = "${var.name}-rds-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress_cidr" {
  count = var.create_rds_security_group && length(var.rds_ingress_cidr_blocks) > 0 ? length(var.rds_ingress_cidr_blocks) : 0

  type              = "ingress"
  from_port         = var.rds_port
  to_port           = var.rds_port
  protocol          = "tcp"
  cidr_blocks       = [var.rds_ingress_cidr_blocks[count.index]]
  security_group_id = aws_security_group.rds[0].id
  description        = "RDS access from ${var.rds_ingress_cidr_blocks[count.index]}"
}

resource "aws_security_group_rule" "rds_ingress_sg" {
  count = var.create_rds_security_group && length(var.rds_ingress_security_groups) > 0 ? length(var.rds_ingress_security_groups) : 0

  type                     = "ingress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  source_security_group_id = var.rds_ingress_security_groups[count.index]
  security_group_id        = aws_security_group.rds[0].id
  description               = "RDS access from security group ${var.rds_ingress_security_groups[count.index]}"
}

resource "aws_security_group_rule" "rds_egress" {
  count = var.create_rds_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds[0].id
  description        = "Allow all outbound traffic"
}

resource "aws_security_group" "elasticache" {
  count = var.create_elasticache_security_group ? 1 : 0

  name        = "${var.name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.security_group_tags,
    {
      Name = "${var.name}-elasticache-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "elasticache_ingress_cidr" {
  count = var.create_elasticache_security_group && length(var.elasticache_ingress_cidr_blocks) > 0 ? length(var.elasticache_ingress_cidr_blocks) : 0

  type              = "ingress"
  from_port         = var.elasticache_port
  to_port           = var.elasticache_port
  protocol          = "tcp"
  cidr_blocks       = [var.elasticache_ingress_cidr_blocks[count.index]]
  security_group_id = aws_security_group.elasticache[0].id
  description        = "ElastiCache access from ${var.elasticache_ingress_cidr_blocks[count.index]}"
}

resource "aws_security_group_rule" "elasticache_ingress_sg" {
  count = var.create_elasticache_security_group && length(var.elasticache_ingress_security_groups) > 0 ? length(var.elasticache_ingress_security_groups) : 0

  type                     = "ingress"
  from_port                = var.elasticache_port
  to_port                  = var.elasticache_port
  protocol                 = "tcp"
  source_security_group_id = var.elasticache_ingress_security_groups[count.index]
  security_group_id        = aws_security_group.elasticache[0].id
  description               = "ElastiCache access from security group ${var.elasticache_ingress_security_groups[count.index]}"
}

resource "aws_security_group_rule" "elasticache_ingress_rds" {
  count = var.create_elasticache_security_group && var.create_rds_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = var.elasticache_port
  to_port                  = var.elasticache_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds[0].id
  security_group_id        = aws_security_group.elasticache[0].id
  description               = "ElastiCache access from RDS security group"
}

resource "aws_security_group_rule" "elasticache_egress" {
  count = var.create_elasticache_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elasticache[0].id
  description        = "Allow all outbound traffic"
}

resource "aws_security_group" "alb" {
  count = var.create_alb_security_group ? 1 : 0

  name        = "${var.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.security_group_tags,
    {
      Name = "${var.name}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  count = var.create_alb_security_group && contains(var.alb_ingress_ports, 80) ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description        = "HTTP from allowed CIDRs"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  count = var.create_alb_security_group && contains(var.alb_ingress_ports, 443) ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description        = "HTTPS from allowed CIDRs"
}

resource "aws_security_group_rule" "alb_egress" {
  count = var.create_alb_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description        = "Allow all outbound traffic"
}

resource "aws_security_group" "nlb" {
  count = var.create_nlb_security_group ? 1 : 0

  name        = "${var.name}-nlb-sg"
  description = "Security group for Network Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.security_group_tags,
    {
      Name = "${var.name}-nlb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "nlb_ingress" {
  count = var.create_nlb_security_group ? length(var.nlb_ingress_ports) : 0

  type              = "ingress"
  from_port         = var.nlb_ingress_ports[count.index]
  to_port           = var.nlb_ingress_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.nlb_ingress_cidr_blocks
  security_group_id = aws_security_group.nlb[0].id
  description        = "Port ${var.nlb_ingress_ports[count.index]} from allowed CIDRs"
}

resource "aws_security_group_rule" "nlb_egress" {
  count = var.create_nlb_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nlb[0].id
  description        = "Allow all outbound traffic"
}

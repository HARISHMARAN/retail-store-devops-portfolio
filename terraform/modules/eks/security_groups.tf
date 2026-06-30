resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = false

  ingress {
    description = "Kubernetes API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cluster_endpoint_public_access_cidrs
  }

  ingress {
    description = "Kubernetes API server (private)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = var.additional_security_group_rules
    content {
      description            = ingress.value.description
      from_port              = ingress.value.from_port
      to_port                = ingress.value.to_port
      protocol               = ingress.value.protocol
      cidr_blocks            = ingress.value.cidr_blocks
      ipv6_cidr_blocks       = ingress.value.ipv6_cidr_blocks
      source_security_group_ids = length(ingress.value.security_groups) > 0 ? ingress.value.security_groups : null
    }
  }

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-cluster-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = false

  dynamic "ingress" {
    for_each = var.cluster_endpoint_private_access ? [1] : []
    content {
      description       = "Cluster API to Node group all traffic"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      security_groups   = [aws_security_group.cluster.id]
    }
  }

  ingress {
    description = "Node to node all ports/protocols"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Primary CNI (Calico VXLAN)"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Calico Typha"
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Calico Health Check"
    from_port   = 9099
    to_port     = 9099
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Calico Health Check (Felix)"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    self        = true
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "cluster_ingress_nodes" {
  count = var.cluster_endpoint_private_access ? 1 : 0

  description              = "Nodes to cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "cluster_egress_nodes_443" {
  description              = "Cluster API to nodes (https)"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "cluster_egress_nodes_kubelet" {
  description              = "Cluster API to node kubelet"
  type                     = "egress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "node_ingress_cluster_443" {
  description              = "Cluster API to nodes (https)"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
}

resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  description              = "Cluster API to node kubelet"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
}

resource "aws_security_group_rule" "node_ingress_cluster_proxy" {
  description              = "Cluster API to node kube-proxy"
  type                     = "ingress"
  from_port                = 10256
  to_port                  = 10256
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "node_ingress_vpc_dns_udp" {
  description       = "DNS UDP from VPC"
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "node_ingress_vpc_dns_tcp" {
  description       = "DNS TCP from VPC"
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group" "_additional" {
  for_each = {
    for idx, rule in var.additional_security_group_rules : idx => rule
    if rule.type == "ingress" && length(rule.cidr_blocks) > 0
  }

  count = local.has_additional_sg ? 1 : 0

  name        = "${var.cluster_name}-additional-sg"
  description = "Additional security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-additional-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

locals {
  has_additional_sg = false
}

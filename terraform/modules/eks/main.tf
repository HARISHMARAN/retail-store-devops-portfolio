resource "aws_eks_cluster" "this" {
  name                          = var.cluster_name
  version                       = var.cluster_version
  role_arn                      = aws_iam_role.cluster.arn
  vpc_config {
    subnet_ids                  = var.private_subnet_ids
    endpoint_private_access     = var.cluster_endpoint_private_access
    endpoint_public_access      = var.cluster_endpoint_public_access
    public_access_cidrs         = var.cluster_endpoint_public_access_cidrs
    security_group_ids          = [aws_security_group.cluster.id]
  }

  dynamic "encryption_config" {
    for_each = var.encryption_config.enabled ? [1] : []
    content {
      provider {
        key_arn = var.encryption_config.kms_key_arn != null ? var.encryption_config.kms_key_arn : aws_kms_key.eks[0].arn
      }
      resources = var.encryption_config.resources
    }
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  kubernetes_network_config {
    ip_family          = var.ip_family
    dynamic "service_ipv4_cidr" {
      for_each = var.service_ipv4_cidr != null ? [var.service_ipv4_cidr] : []
      content {
        service_ipv4_cidr = var.service_ipv4_cidr
      }
    }
  }

  access_config {
    authentication_mode = var.authentication_mode
    dynamic "bootstrap_cluster_creator_admin_permissions" {
      for_each = var.enable_cluster_creator_admin_permissions ? [1] : []
      content {
        cluster_creator_admin_permissions = true
      }
    }
  }

  timeouts {
    create = try(var.cluster_timeouts.create, "30m")
    update = try(var.cluster_timeouts.update, "60m")
    delete = try(var.cluster_timeouts.delete, "30m")
  }

  tags = merge(var.tags, var.cluster_tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_cloudwatch_log_group.eks,
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-logs"
  })
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_default_addons ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  dynamic "addon_version" {
    for_each = try(var.cluster_addons["vpc-cni"].addon_version, null) != null ? [1] : []
    content {
      addon_version = var.cluster_addons["vpc-cni"].addon_version
    }
  }
  resolve_conflicts_on_create = try(var.cluster_addons["vpc-cni"].resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(var.cluster_addons["vpc-cni"].resolve_conflicts_on_update, "OVERWRITE")
  configuration_values = jsonencode({
    env = {
      ENABLE_POD_ENI                    = tostring(var.vpc_cni_config.enable_pod_eni)
      POD_SECURITY_GROUP_ENFORCING_MODE = var.vpc_cni_config.security_group_mode
    }
  })
  service_account_role_arn = aws_iam_role.vpc_cni_irsa[0].arn

  depends_on = [
    aws_eks_node_group.general,
  ]
}

resource "aws_eks_addon" "coredns" {
  count = var.enable_default_addons ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  dynamic "addon_version" {
    for_each = try(var.cluster_addons["coredns"].addon_version, null) != null ? [1] : []
    content {
      addon_version = var.cluster_addons["coredns"].addon_version
    }
  }
  resolve_conflicts_on_create = try(var.cluster_addons["coredns"].resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(var.cluster_addons["coredns"].resolve_conflicts_on_update, "OVERWRITE")

  depends_on = [
    aws_eks_node_group.general,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_default_addons ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  dynamic "addon_version" {
    for_each = try(var.cluster_addons["kube-proxy"].addon_version, null) != null ? [1] : []
    content {
      addon_version = var.cluster_addons["kube-proxy"].addon_version
    }
  }
  resolve_conflicts_on_create = try(var.cluster_addons["kube-proxy"].resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(var.cluster_addons["kube-proxy"].resolve_conflicts_on_update, "OVERWRITE")
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_default_addons ? 1 : 0

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa[0].arn

  dynamic "addon_version" {
    for_each = try(var.cluster_addons["aws-ebs-csi-driver"].addon_version, null) != null ? [1] : []
    content {
      addon_version = var.cluster_addons["aws-ebs-csi-driver"].addon_version
    }
  }
  resolve_conflicts_on_create = try(var.cluster_addons["aws-ebs-csi-driver"].resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(var.cluster_addons["aws-ebs-csi-driver"].resolve_conflicts_on_update, "OVERWRITE")
  configuration_values = jsonencode({
    defaultStorageClass = {
      enabled = true
    }
  })
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-oidc-provider"
  })
}

resource "aws_eks_access_entry" "cluster_admin" {
  for_each = toset(var.admins)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = toset(var.admins)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}

resource "time_sleep" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.this]

  create_duration = var.dataplane_wait_duration

  triggers = {
    cluster_endpoint = aws_eks_cluster.this.endpoint
  }
}

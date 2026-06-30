resource "aws_eks_node_group" "general" {
  for_each = var.managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${each.key}-${var.cluster_name}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.private_subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size       = each.value.disk_size

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  dynamic "labels" {
    for_each = each.value.labels
    content {
      key   = labels.key
      value = labels.value
    }
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "launch_template" {
    for_each = each.value.capacity_type == "SPOT" ? [1] : []
    content {
      id      = aws_launch_template.spot[0].id
      version = "$Latest"
    }
  }

  lifecycle {
    ignore_changes = [initial_labels]
  }

  tags = merge(var.tags, var.node_group_tags, each.value.tags, {
    Name                                           = "${var.cluster_name}-${each.key}"
    "kubernetes.io/cluster/${var.cluster_name}"    = "owned"
    "k8s.io/cluster/${var.cluster_name}"           = "owned"
    "karpenter.sh/discovery/${var.cluster_name}"   = var.enable_karpenter ? "owned" : null
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]
}

resource "aws_eks_node_group" "compute" {
  count = var.enable_compute_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-compute"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.compute_node_group_config.instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = 100

  scaling_config {
    min_size     = var.compute_node_group_config.min_size
    max_size     = var.compute_node_group_config.max_size
    desired_size = var.compute_node_group_config.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels {
    key   = "node-type"
    value = "compute"
  }
  labels {
    key   = "workload"
    value = "compute-optimized"
  }

  tags = merge(var.tags, var.node_group_tags, {
    Name                                           = "${var.cluster_name}-compute"
    "kubernetes.io/cluster/${var.cluster_name}"    = "owned"
    "k8s.io/cluster/${var.cluster_name}"           = "owned"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]
}

resource "aws_eks_node_group" "memory" {
  count = var.enable_memory_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-memory"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.memory_node_group_config.instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = 100

  scaling_config {
    min_size     = var.memory_node_group_config.min_size
    max_size     = var.memory_node_group_config.max_size
    desired_size = var.memory_node_group_config.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels {
    key   = "node-type"
    value = "memory"
  }
  labels {
    key   = "workload"
    value = "memory-optimized"
  }

  tags = merge(var.tags, var.node_group_tags, {
    Name                                           = "${var.cluster_name}-memory"
    "kubernetes.io/cluster/${var.cluster_name}"    = "owned"
    "k8s.io/cluster/${var.cluster_name}"           = "owned"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]
}

resource "aws_eks_node_group" "spot" {
  count = var.enable_spot_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-spot"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.spot_node_group_config.instance_types
  capacity_type  = "SPOT"
  disk_size      = 50

  scaling_config {
    min_size     = var.spot_node_group_config.min_size
    max_size     = var.spot_node_group_config.max_size
    desired_size = var.spot_node_group_config.desired_size
  }

  update_config {
    max_unavailable_percentage = 50
  }

  labels {
    key   = "node-type"
    value = "spot"
  }
  labels {
    key   = "workload"
    value = "non-critical"
  }
  labels {
    key   = "karpenter.sh/capacity-type"
    value = "spot"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, var.node_group_tags, {
    Name                                           = "${var.cluster_name}-spot"
    "kubernetes.io/cluster/${var.cluster_name}"    = "owned"
    "k8s.io/cluster/${var.cluster_name}"           = "owned"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]
}

resource "aws_eks_node_group" "gpu" {
  count = var.enable_gpu_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-gpu"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.gpu_node_group_config.instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = 200

  scaling_config {
    min_size     = var.gpu_node_group_config.min_size
    max_size     = var.gpu_node_group_config.max_size
    desired_size = var.gpu_node_group_config.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  labels {
    key   = "node-type"
    value = "gpu"
  }
  labels {
    key   = "workload"
    value = "ml-ai"
  }
  labels {
    key   = "nvidia.com/gpu"
    value = "true"
  }

  dynamic "taint" {
    for_each = var.enable_efa_support ? [1] : []
    content {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  tags = merge(var.tags, var.node_group_tags, {
    Name                                           = "${var.cluster_name}-gpu"
    "kubernetes.io/cluster/${var.cluster_name}"    = "owned"
    "k8s.io/cluster/${var.cluster_name}"           = "owned"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]
}

resource "aws_launch_template" "spot" {
  count = var.enable_spot_node_group || anytrue([for ng in var.managed_node_groups : ng.capacity_type == "SPOT"]) ? 1 : 0

  name_prefix = "${var.cluster_name}-spot-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.encryption_config.enabled ? (var.encryption_config.kms_key_arn != null ? var.encryption_config.kms_key_arn : aws_kms_key.eks[0].arn) : null
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.this.endpoint
    cluster_certificate = aws_eks_cluster.this.certificate_authority[0].data
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name                                        = "${var.cluster_name}-spot"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
  }

  tags = var.tags
}

resource "aws_launch_template" "gpu" {
  count = var.enable_gpu_node_group && var.enable_efa_support ? 1 : 0

  name_prefix = "${var.cluster_name}-gpu-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 200
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.this.endpoint
    cluster_certificate = aws_eks_cluster.this.certificate_authority[0].data
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_group_ids          = [aws_security_group.node.id]
    dynamic "efa_only" {
      for_each = var.enable_efa_support ? [1] : []
      content {}
    }
  }

  placement {
    tenancy = "default"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name                                        = "${var.cluster_name}-gpu"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
  }

  tags = var.tags
}

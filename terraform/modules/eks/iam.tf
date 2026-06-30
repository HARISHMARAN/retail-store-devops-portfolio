data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    sid     = "EKSClusterAssumeRole"
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name                 = "${var.cluster_name}-cluster-role"
  assume_role_policy   = data.aws_iam_policy_document.cluster_assume_role.json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    sid     = "EKSNodeAssumeRole"
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name                 = "${var.cluster_name}-node-role"
  assume_role_policy   = data.aws_iam_policy_document.node_assume_role.json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

data "aws_iam_policy_document" "vpc_cni_assume_role" {
  count = var.enable_default_addons ? 1 : 0

  statement {
    sid     = "VPCCNIIrsaAssumeRole"
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni_irsa" {
  count = var.enable_default_addons ? 1 : 0

  name                 = "${var.cluster_name}-vpc-cni-irsa"
  assume_role_policy   = data.aws_iam_policy_document.vpc_cni_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-cni-irsa"
  })
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = var.enable_default_addons ? 1 : 0

  statement {
    sid    = "EBSCSIIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_irsa" {
  count = var.enable_default_addons ? 1 : 0

  name                 = "${var.cluster_name}-ebs-csi-irsa"
  assume_role_policy   = data.aws_iam_policy_document.ebs_csi_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi-irsa"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_default_addons ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa[0].name
}

data "aws_iam_policy_document" "alb_controller_assume_role" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  statement {
    sid    = "ALBControllerIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller_irsa" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name                 = "${var.cluster_name}-alb-controller-irsa"
  assume_role_policy   = data.aws_iam_policy_document.alb_controller_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-controller-irsa"
  })
}

data "aws_iam_policy_document" "alb_controller_policy" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  statement {
    sid    = "ALBControllerPolicy"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ALBControllerCreatePolicy"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ALBControllerDeletePolicy"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name   = "${var.cluster_name}-alb-controller-policy"
  policy = data.aws_iam_policy_document.alb_controller_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  policy_arn = aws_iam_policy.alb_controller[0].arn
  role       = aws_iam_role.alb_controller_irsa[0].name
}

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    sid    = "ClusterAutoscalerIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler_irsa" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name                 = "${var.cluster_name}-cluster-autoscaler-irsa"
  assume_role_policy   = data.aws_iam_policy_document.cluster_autoscaler_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-autoscaler-irsa"
  })
}

data "aws_iam_policy_document" "cluster_autoscaler_policy" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    sid    = "ClusterAutoscalerPolicy"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name   = "${var.cluster_name}-cluster-autoscaler-policy"
  policy = data.aws_iam_policy_document.cluster_autoscaler_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler_irsa[0].name
}

data "aws_iam_policy_document" "external_dns_assume_role" {
  count = var.enable_external_dns ? 1 : 0

  statement {
    sid    = "ExternalDnsIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns_irsa" {
  count = var.enable_external_dns ? 1 : 0

  name                 = "${var.cluster_name}-external-dns-irsa"
  assume_role_policy   = data.aws_iam_policy_document.external_dns_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-external-dns-irsa"
  })
}

data "aws_iam_policy_document" "external_dns_policy" {
  count = var.enable_external_dns ? 1 : 0

  statement {
    sid    = "ExternalDnsPolicy"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [for zone in var.external_dns_hosted_zone_ids : "arn:aws:route53:::hostedzone/${zone}"]
  }

  statement {
    sid    = "ExternalDnsListPolicy"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name   = "${var.cluster_name}-external-dns-policy"
  policy = data.aws_iam_policy_document.external_dns_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  policy_arn = aws_iam_policy.external_dns[0].arn
  role       = aws_iam_role.external_dns_irsa[0].name
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  count = var.enable_external_secrets ? 1 : 0

  statement {
    sid    = "ExternalSecretsIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets_irsa" {
  count = var.enable_external_secrets ? 1 : 0

  name                 = "${var.cluster_name}-external-secrets-irsa"
  assume_role_policy   = data.aws_iam_policy_document.external_secrets_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-external-secrets-irsa"
  })
}

data "aws_iam_policy_document" "external_secrets_policy" {
  count = var.enable_external_secrets ? 1 : 0

  statement {
    sid    = "ExternalSecretsSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = length(var.secrets_manager_arns) > 0 ? var.secrets_manager_arns : ["*"]
  }

  statement {
    sid    = "ExternalSecretsSSM"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]
    resources = length(var.ssm_parameter_arns) > 0 ? var.ssm_parameter_arns : ["*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name   = "${var.cluster_name}-external-secrets-policy"
  policy = data.aws_iam_policy_document.external_secrets_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  policy_arn = aws_iam_policy.external_secrets[0].arn
  role       = aws_iam_role.external_secrets_irsa[0].name
}

data "aws_iam_policy_document" "cloudwatch_agent_assume_role" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  statement {
    sid    = "CloudWatchAgentIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_agent_irsa" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  name                 = "${var.cluster_name}-cloudwatch-agent-irsa"
  assume_role_policy   = data.aws_iam_policy_document.cloudwatch_agent_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cloudwatch-agent-irsa"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_agent_irsa[0].name
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    sid    = "KarpenterIrsaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_irsa" {
  count = var.enable_karpenter ? 1 : 0

  name                 = "${var.cluster_name}-karpenter-irsa"
  assume_role_policy   = data.aws_iam_policy_document.karpenter_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-karpenter-irsa"
  })
}

data "aws_iam_policy_document" "karpenter_policy" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    sid    = "KarpenterControllerPolicy"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "iam:PassRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "pricing:GetProducts",
      "ssm:GetParameter",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "KarpenterPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node[0].arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name   = "${var.cluster_name}-karpenter-policy"
  policy = data.aws_iam_policy_document.karpenter_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = aws_iam_policy.karpenter[0].arn
  role       = aws_iam_role.karpenter_irsa[0].name
}

data "aws_iam_policy_document" "karpenter_node_assume_role" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    sid    = "KarpenterNodeAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0

  name                 = "${var.cluster_name}-karpenter-node-role"
  assume_role_policy   = data.aws_iam_policy_document.karpenter_node_assume_role[0].json
  permissions_boundary = null

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-karpenter-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_registry_policy" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm_policy" {
  count = var.enable_karpenter ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "${var.cluster_name}-karpenter-node-profile"
  role = aws_iam_role.karpenter_node[0].name

  tags = var.tags
}

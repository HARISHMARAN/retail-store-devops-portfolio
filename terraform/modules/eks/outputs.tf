output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS worker nodes"
  value       = aws_security_group.node.id
}

output "cluster_primary_security_group_id" {
  description = "EKS cluster primary security group ID (created by EKS)"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.this[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.this[0].url : null
}

output "oidc_provider_issuer" {
  description = "Issuer URL for the OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "eks_kubeconfig" {
  description = "kubectl configuration for connecting to the EKS cluster"
  value = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name    = aws_eks_cluster.this.name
    cluster_endpoint = aws_eks_cluster.this.endpoint
    cluster_ca       = aws_eks_cluster.this.certificate_authority[0].data
  })
  sensitive = true
}

output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.node.arn
}

output "node_group_arns" {
  description = "ARNs of the EKS managed node groups"
  value       = { for k, v in aws_eks_node_group.general : k => v.arn }
}

output "compute_node_group_arn" {
  description = "ARN of the compute-optimized node group"
  value       = var.enable_compute_node_group ? aws_eks_node_group.compute[0].arn : null
}

output "memory_node_group_arn" {
  description = "ARN of the memory-optimized node group"
  value       = var.enable_memory_node_group ? aws_eks_node_group.memory[0].arn : null
}

output "spot_node_group_arn" {
  description = "ARN of the spot instance node group"
  value       = var.enable_spot_node_group ? aws_eks_node_group.spot[0].arn : null
}

output "gpu_node_group_arn" {
  description = "ARN of the GPU node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gpu[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS logs"
  value       = aws_cloudwatch_log_group.eks.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS logs"
  value       = aws_cloudwatch_log_group.eks.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS encryption"
  value       = var.create_kms_key && var.encryption_config.enabled ? aws_kms_key.eks[0].arn : null
}

output "kms_key_id" {
  description = "ID of the KMS key used for EKS encryption"
  value       = var.create_kms_key && var.encryption_config.enabled ? aws_kms_key.eks[0].key_id : null
}

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IRSA role"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.alb_controller_irsa[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IRSA role"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler_irsa[0].arn : null
}

output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS IRSA role"
  value       = var.enable_external_dns ? aws_iam_role.external_dns_irsa[0].arn : null
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IRSA role"
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets_irsa[0].arn : null
}

output "cloudwatch_agent_role_arn" {
  description = "ARN of the CloudWatch Agent IRSA role"
  value       = var.enable_cloudwatch_agent ? aws_iam_role.cloudwatch_agent_irsa[0].arn : null
}

output "karpenter_role_arn" {
  description = "ARN of the Karpenter IRSA role"
  value       = var.enable_karpenter ? aws_iam_role.karpenter_irsa[0].arn : null
}

output "karpenter_node_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = var.enable_karpenter ? aws_iam_role.karpenter_node[0].arn : null
}

output "karpenter_instance_profile_name" {
  description = "Name of the Karpenter instance profile"
  value       = var.enable_karpenter ? aws_iam_instance_profile.karpenter[0].name : null
}

output "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI IRSA role"
  value       = var.enable_default_addons ? aws_iam_role.vpc_cni_irsa[0].arn : null
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IRSA role"
  value       = var.enable_default_addons ? aws_iam_role.ebs_csi_irsa[0].arn : null
}

output "irsa_role_arns" {
  description = "Map of IRSA role ARNs"
  value = {
    alb_controller    = var.enable_aws_load_balancer_controller ? aws_iam_role.alb_controller_irsa[0].arn : null
    cluster_autoscaler = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler_irsa[0].arn : null
    external_dns      = var.enable_external_dns ? aws_iam_role.external_dns_irsa[0].arn : null
    external_secrets  = var.enable_external_secrets ? aws_iam_role.external_secrets_irsa[0].arn : null
    cloudwatch_agent  = var.enable_cloudwatch_agent ? aws_iam_role.cloudwatch_agent_irsa[0].arn : null
    karpenter         = var.enable_karpenter ? aws_iam_role.karpenter_irsa[0].arn : null
    vpc_cni           = var.enable_default_addons ? aws_iam_role.vpc_cni_irsa[0].arn : null
    ebs_csi           = var.enable_default_addons ? aws_iam_role.ebs_csi_irsa[0].arn : null
  }
}

output "addons" {
  description = "EKS addons information"
  value = {
    vpc_cni        = var.enable_default_addons ? aws_eks_addon.vpc_cni[0].arn : null
    coredns        = var.enable_default_addons ? aws_eks_addon.coredns[0].arn : null
    kube_proxy     = var.enable_default_addons ? aws_eks_addon.kube_proxy[0].arn : null
    ebs_csi_driver = var.enable_default_addons ? aws_eks_addon.ebs_csi_driver[0].arn : null
  }
}

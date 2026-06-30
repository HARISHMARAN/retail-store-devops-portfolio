terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "eks/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform-eks-${var.environment}"
  }
}

provider "aws" {
  alias  = "dns"
  region = var.region

  assume_role {
    role_arn     = var.dns_account_role_arn
    session_name = "terraform-eks-dns"
  }
}

locals {
  cluster_name   = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment  = var.environment
    Project      = var.project_name
    ManagedBy    = "terraform"
    Repository   = "retail-store-sample-app"
  })
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.vpc_state_bucket
    key    = "vpc/${var.environment}/terraform.tfstate"
    region = var.region
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  public_subnet_ids       = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_log_retention_days           = var.cluster_log_retention_days

  encryption_config = {
    enabled   = var.encryption_enabled
    resources = ["secrets"]
  }

  managed_node_groups = var.managed_node_groups

  enable_compute_node_group = var.enable_compute_node_group
  enable_memory_node_group  = var.enable_memory_node_group
  enable_spot_node_group    = var.enable_spot_node_group
  enable_gpu_node_group     = var.enable_gpu_node_group

  enable_karpenter           = var.enable_karpenter
  enable_cluster_autoscaler  = var.enable_cluster_autoscaler
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_external_dns        = var.enable_external_dns
  enable_external_secrets    = var.enable_external_secrets
  enable_cloudwatch_agent    = var.enable_cloudwatch_agent

  external_dns_hosted_zone_ids = var.external_dns_hosted_zone_ids
  secrets_manager_arns         = var.secrets_manager_arns
  ssm_parameter_arns           = var.ssm_parameter_arns

  admins = var.admins

  tags = local.common_tags
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_kubeconfig" {
  description = "kubectl config for the cluster"
  value       = module.eks.eks_kubeconfig
  sensitive   = true
}

output "irsa_role_arns" {
  description = "Map of IRSA role ARNs for service accounts"
  value       = module.eks.irsa_role_arns
}

output "node_group_arns" {
  description = "ARNs of the managed node groups"
  value       = module.eks.node_group_arns
}

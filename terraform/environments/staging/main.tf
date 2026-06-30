terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "retail-store-terraform-state"
    key            = "staging/eks/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "retail-store-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "retail-store"
    })
  }
}

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  vpc_name             = "${var.cluster_name}-vpc"
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = var.tags
}

module "security" {
  source = "../modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  tags        = var.tags
}

module "eks" {
  source = "../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids        = module.vpc.public_subnet_ids

  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = var.allowed_cidrs

  managed_node_groups = var.managed_node_groups

  enable_irsa_for_alb_controller  = true
  enable_irsa_for_external_dns    = true
  enable_irsa_for_external_secrets = true

  tags = var.tags
}

module "monitoring" {
  source = "../modules/monitoring"

  cluster_name    = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_amazon_managed_prometheus = var.enable_amazon_managed_prometheus
  enable_amazon_managed_grafana    = var.enable_amazon_managed_grafana

  tags = var.tags
}

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "retail-store"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers"
  type        = list(string)
  default     = []
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "managed_node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = map(string)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    general = {
      instance_types = ["m5.large", "m6i.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      labels = {
        workload = "general"
      }
    }
  }
}

variable "enable_compute_node_group" {
  description = "Enable compute-optimized node group"
  type        = bool
  default     = false
}

variable "enable_memory_node_group" {
  description = "Enable memory-optimized node group"
  type        = bool
  default     = false
}

variable "enable_spot_node_group" {
  description = "Enable spot instance node group"
  type        = bool
  default     = false
}

variable "enable_gpu_node_group" {
  description = "Enable GPU node group for ML workloads"
  type        = bool
  default     = false
}

variable "enable_karpenter" {
  description = "Enable Karpenter for node autoscaling"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler for managed node groups"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable ExternalDNS"
  type        = bool
  default     = false
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch Agent for metrics and logs"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public cluster endpoint"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 30
}

variable "encryption_enabled" {
  description = "Enable encryption for EKS secrets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "admins" {
  description = "List of IAM ARNs that should have admin access to the cluster"
  type        = list(string)
  default     = []
}

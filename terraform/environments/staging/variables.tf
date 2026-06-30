variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "retail-store-staging"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.110.0/24", "10.0.120.0/24"]
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access the cluster endpoint"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "managed_node_groups" {
  description = "Configuration for EKS managed node groups"
  type = map(object({
    instance_types = list(string)
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
    labels         = map(string)
    taints         = list(object({ key = string, value = string, effect = string }))
  }))
  default = {
    general = {
      instance_types = ["m5.large", "m5a.large"]
      disk_size      = 100
      min_size       = 2
      max_size       = 10
      desired_size   = 2
      capacity_type  = "ON_DEMAND"
      labels = {
        workload = "general"
      }
      taints = []
    }
    compute = {
      instance_types = ["c5.large", "c5a.large"]
      disk_size      = 100
      min_size       = 1
      max_size       = 10
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
      labels = {
        workload = "compute"
      }
      taints = []
    }
    spot = {
      instance_types = ["m5.large", "m5a.large", "m5ad.large"]
      disk_size      = 50
      min_size       = 0
      max_size       = 10
      desired_size   = 0
      capacity_type  = "SPOT"
      labels = {
        workload  = "batch"
        spot      = "true"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}

variable "enable_amazon_managed_prometheus" {
  description = "Enable Amazon Managed Prometheus"
  type        = bool
  default     = true
}

variable "enable_amazon_managed_grafana" {
  description = "Enable Amazon Managed Grafana"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Team        = "platform"
    Project     = "retail-store"
    Repo        = "retail-store-sample-app"
    CostCenter  = "engineering"
  }
}

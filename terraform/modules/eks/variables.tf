variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes and control plane"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "List of EKS control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 30
}

variable "encryption_config" {
  description = "Configuration for EKS cluster encryption"
  type = object({
    enabled        = bool
    resources      = list(string)
    kms_key_arn   = optional(string)
  })
  default = {
    enabled   = true
    resources = ["secrets"]
  }
}

variable "kms_key_deletion_window" {
  description = "Waiting period before KMS key deletion (7-30 days)"
  type        = number
  default     = 30
}

variable "enable_karpenter" {
  description = "Enable Karpenter for node autoscaling"
  type        = bool
  default     = false
}

variable "karpenter_version" {
  description = "Version of Karpenter to deploy"
  type        = string
  default     = "v0.33.0"
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler for managed node groups"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "irsa_service_accounts" {
  description = "List of service account configurations for IRSA"
  type = map(object({
    namespace      = string
    policies       = list(string)
    policy_json    = optional(string)
  }))
  default = {}
}

variable "managed_node_groups" {
  description = "Managed node group configurations"
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
    tags           = optional(map(string), {})
    subnet_ids     = optional(list(string), [])
  }))
  default = {
    general = {
      instance_types = ["m5.large", "m6i.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      min_size       = 1
      max_size       = 5
      desired_size   = 2
      labels = {
        "node-type" = "general"
      }
    }
  }
}

variable "enable_compute_node_group" {
  description = "Enable compute-optimized node group"
  type        = bool
  default     = false
}

variable "compute_node_group_config" {
  description = "Configuration for compute-optimized node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
  default = {
    instance_types = ["c5.large", "c6i.large"]
    min_size       = 0
    max_size       = 3
    desired_size   = 0
  }
}

variable "enable_memory_node_group" {
  description = "Enable memory-optimized node group"
  type        = bool
  default     = false
}

variable "memory_node_group_config" {
  description = "Configuration for memory-optimized node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
  default = {
    instance_types = ["r5.large", "r6i.large"]
    min_size       = 0
    max_size       = 3
    desired_size   = 0
  }
}

variable "enable_spot_node_group" {
  description = "Enable spot instance node group for non-critical workloads"
  type        = bool
  default     = false
}

variable "spot_node_group_config" {
  description = "Configuration for spot instance node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
  default = {
    instance_types = ["m5.large", "m6i.large", "c5.large"]
    min_size       = 0
    max_size       = 5
    desired_size   = 1
  }
}

variable "enable_gpu_node_group" {
  description = "Enable GPU node group for ML/AI workloads"
  type        = bool
  default     = false
}

variable "gpu_node_group_config" {
  description = "Configuration for GPU node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
  })
  default = {
    instance_types = ["g5.xlarge", "g4dn.xlarge"]
    min_size       = 0
    max_size       = 2
    desired_size   = 0
  }
}

variable "enable_efa_support" {
  description = "Enable Elastic Fabric Adapter (EFA) support on GPU nodes"
  type        = bool
  default     = false
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller IRSA"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable ExternalDNS IRSA"
  type        = bool
  default     = false
}

variable "external_dns_hosted_zone_ids" {
  description = "Route53 hosted zone IDs that ExternalDNS can manage"
  type        = list(string)
  default     = []
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator IRSA"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "ARNs of Secrets Manager secrets accessible to External Secrets Operator"
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "ARNs of SSM parameters accessible to External Secrets Operator"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch agent for metrics and logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for container logs"
  type        = string
  default     = ""
}

variable "cluster_addons" {
  description = "Map of EKS cluster addons to enable with configurations"
  type = map(object({
    addon_version = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    configuration_values = optional(string)
  }))
  default = {}
}

variable "enable_default_addons" {
  description = "Enable default EKS addons (vpc-cni, coredns, kube-proxy, ebs-csi-driver)"
  type        = bool
  default     = true
}

variable "vpc_cni_config" {
  description = "VPC CNI addon configuration"
  type = object({
    enable_pod_eni     = bool
    eni_config_label   = string
    security_group_mode = string
  })
  default = {
    enable_pod_eni      = true
    eni_config_label    = "topology.k8s.aws/zone"
    security_group_mode = "standard"
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags specific to the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Tags to apply to node groups"
  type        = map(string)
  default     = {}
}

variable "create_kms_key" {
  description = "Whether to create a new KMS key for EKS encryption"
  type        = bool
  default     = true
}

variable "admins" {
  description = "List of IAM ARNs that should have system:masters access to the cluster"
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to map to Kubernetes rbac groups"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to map to Kubernetes rbac groups"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses (IPv4 or IPv6)"
  type        = string
  default     = "ipv4"
}

variable "service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IPs from"
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "Authentication mode for the cluster (API_AND_CONFIG_MAP or CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "enable_kubernetes_api_access" {
  description = "Enable security group rules for Kubernetes API access"
  type        = bool
  default     = true
}

variable "additional_security_group_rules" {
  description = "Additional security group rules for the cluster"
  type = list(object({
    type              = string
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string), [])
    ipv6_cidr_blocks  = optional(list(string), [])
    security_groups   = optional(list(string), [])
    description       = string
  }))
  default = []
}

variable "cluster_timeouts" {
  description = "Timeouts for EKS cluster operations"
  type = object({
    create = optional(string, "30m")
    update = optional(string, "60m")
    delete = optional(string, "30m")
  })
  default = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin permissions via access entry"
  type        = bool
  default     = true
}

variable "associate_primary_security_group" {
  description = "Associate the primary security group with nodes"
  type        = bool
  default     = false
}

variable "create_cni_ipv6_ippool" {
  description = "Create IPv6 IP pool for VPC CNI"
  type        = bool
  default     = false
}

variable "dataplane_wait_duration" {
  description = "Duration to wait for dataplane to become stable"
  type        = string
  default     = "90s"
}

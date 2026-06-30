variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "create_rds_security_group" {
  description = "Whether to create security group for RDS"
  type        = bool
  default     = true
}

variable "rds_port" {
  description = "Port for RDS database"
  type        = number
  default     = 3306
}

variable "rds_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "rds_ingress_security_groups" {
  description = "List of security group IDs allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "create_elasticache_security_group" {
  description = "Whether to create security group for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_port" {
  description = "Port for ElastiCache Redis"
  type        = number
  default     = 6379
}

variable "elasticache_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to ElastiCache"
  type        = list(string)
  default     = []
}

variable "elasticache_ingress_security_groups" {
  description = "List of security group IDs allowed to connect to ElastiCache"
  type        = list(string)
  default     = []
}

variable "create_alb_security_group" {
  description = "Whether to create security group for ALB"
  type        = bool
  default     = true
}

variable "alb_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_ingress_ports" {
  description = "List of ports allowed for ALB ingress"
  type        = list(number)
  default     = [80, 443]
}

variable "create_nlb_security_group" {
  description = "Whether to create security group for NLB"
  type        = bool
  default     = true
}

variable "nlb_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to NLB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nlb_ingress_ports" {
  description = "List of ports allowed for NLB ingress"
  type        = list(number)
  default     = [80, 443]
}

variable "create_eks_pod_iam_roles" {
  description = "Whether to create IAM roles for EKS pods"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
  default     = ""
}

variable "eks_pod_service_accounts" {
  description = "Map of EKS pod service accounts to create IAM roles for"
  type = map(object({
    namespace       = string
    policy_document = optional(string, "")
    policy_arns     = optional(list(string), [])
  }))
  default = {}
}

variable "create_secrets_manager_secrets" {
  description = "Whether to create Secrets Manager secrets"
  type        = bool
  default     = true
}

variable "secrets" {
  description = "Map of secrets to create in Secrets Manager"
  type = map(object({
    description             = optional(string, "")
    secret_string_template = optional(string, "")
    random_password_length = optional(number, 32)
    recovery_window_in_days = optional(number, 30)
    generate_random_password = optional(bool, true)
  }))
  default = {}
}

variable "create_kms_key" {
  description = "Whether to create KMS key for secret encryption"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "Duration in days after which the KMS key is deleted"
  type        = number
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "Whether to enable key rotation for the KMS key"
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "List of IAM ARNs for KMS key administrators"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM ARNs for KMS key users"
  type        = list(string)
  default     = []
}

variable "create_waf_web_acl" {
  description = "Whether to create WAF Web ACL"
  type        = bool
  default     = true
}

variable "waf_scope" {
  description = "Scope of WAF Web ACL - REGIONAL or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"
}

variable "waf_default_action" {
  description = "Default action for WAF Web ACL - allow or block"
  type        = string
  default     = "allow"
}

variable "waf_enable_rate_limit" {
  description = "Whether to enable rate-based rule in WAF"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF rate-based rule"
  type        = number
  default     = 2000
}

variable "waf_enable_aws_managed_rules" {
  description = "Whether to enable AWS managed rule sets"
  type        = bool
  default     = true
}

variable "waf_aws_managed_rule_sets" {
  description = "List of AWS managed rule sets to enable"
  type = list(object({
    name        = string
    priority    = number
    vendor_name = string
  }))
  default = [
    {
      name        = "AWSManagedRulesCommonRuleSet"
      priority    = 10
      vendor_name = "AWS"
    },
    {
      name        = "AWSManagedRulesSQLInjectionRuleSet"
      priority    = 20
      vendor_name = "AWS"
    },
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      priority    = 30
      vendor_name = "AWS"
    }
  ]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for security groups"
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "Additional tags for IAM roles"
  type        = map(string)
  default     = {}
}

variable "secrets_tags" {
  description = "Additional tags for secrets"
  type        = map(string)
  default     = {}
}

variable "waf_tags" {
  description = "Additional tags for WAF"
  type        = map(string)
  default     = {}
}

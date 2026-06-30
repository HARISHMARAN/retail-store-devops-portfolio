output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = element(concat(aws_security_group.rds[*].id, [""]), 0)
}

output "rds_security_group_arn" {
  description = "ARN of the RDS security group"
  value       = element(concat(aws_security_group.rds[*].arn, [""]), 0)
}

output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = element(concat(aws_security_group.elasticache[*].id, [""]), 0)
}

output "elasticache_security_group_arn" {
  description = "ARN of the ElastiCache security group"
  value       = element(concat(aws_security_group.elasticache[*].arn, [""]), 0)
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = element(concat(aws_security_group.alb[*].id, [""]), 0)
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = element(concat(aws_security_group.alb[*].arn, [""]), 0)
}

output "nlb_security_group_id" {
  description = "ID of the NLB security group"
  value       = element(concat(aws_security_group.nlb[*].id, [""]), 0)
}

output "nlb_security_group_arn" {
  description = "ARN of the NLB security group"
  value       = element(concat(aws_security_group.nlb[*].arn, [""]), 0)
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = element(concat(aws_kms_key.secrets[*].arn, [""]), 0)
}

output "kms_key_id" {
  description = "ID of the KMS key for secrets encryption"
  value       = element(concat(aws_kms_key.secrets[*].key_id, [""]), 0)
}

output "kms_key_alias" {
  description = "Alias of the KMS key for secrets encryption"
  value       = element(concat(aws_kms_alias.secrets[*].name, [""]), 0)
}

output "kms_key_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = element(concat(aws_kms_alias.secrets[*].arn, [""]), 0)
}

output "secrets_manager_secret_arns" {
  description = "Map of Secrets Manager secret ARNs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secrets_manager_secret_ids" {
  description = "Map of Secrets Manager secret IDs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secrets_manager_secret_names" {
  description = "Map of Secrets Manager secret names"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "eks_pod_iam_role_arns" {
  description = "Map of EKS pod IAM role ARNs"
  value       = { for k, v in aws_iam_role.eks_pod : k => v.arn }
}

output "eks_pod_iam_role_names" {
  description = "Map of EKS pod IAM role names"
  value       = { for k, v in aws_iam_role.eks_pod : k => v.name }
}

output "eks_pod_iam_role_ids" {
  description = "Map of EKS pod IAM role IDs"
  value       = { for k, v in aws_iam_role.eks_pod : k => v.id }
}

output "secrets_access_policy_arn" {
  description = "ARN of the secrets access IAM policy"
  value       = element(concat(aws_iam_policy.secrets_access[*].arn, [""]), 0)
}

output "secrets_access_policy_id" {
  description = "ID of the secrets access IAM policy"
  value       = element(concat(aws_iam_policy.secrets_access[*].id, [""]), 0)
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = element(concat(aws_wafv2_web_acl.this[*].arn, [""]), 0)
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = element(concat(aws_wafv2_web_acl.this[*].id, [""]), 0)
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = element(concat(aws_wafv2_web_acl.this[*].name, [""]), 0)
}

output "waf_web_acl_capacity" {
  description = "Capacity units consumed by the WAF Web ACL"
  value       = element(concat(aws_wafv2_web_acl.this[*].capacity, [""]), 0)
}

output "waf_ip_set_arn" {
  description = "ARN of the WAF IP set"
  value       = element(concat(aws_wafv2_ip_set.this[*].arn, [""]), 0)
}

output "waf_regex_pattern_set_arn" {
  description = "ARN of the WAF regex pattern set"
  value       = element(concat(aws_wafv2_regex_pattern_set.this[*].arn, [""]), 0)
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    rds        = element(concat(aws_security_group.rds[*].id, [""]), 0)
    elasticache = element(concat(aws_security_group.elasticache[*].id, [""]), 0)
    alb        = element(concat(aws_security_group.alb[*].id, [""]), 0)
    nlb        = element(concat(aws_security_group.nlb[*].id, [""]), 0)
  }
}

output "all_security_group_ids" {
  description = "List of all security group IDs"
  value = compact([
    element(concat(aws_security_group.rds[*].id, [""]), 0),
    element(concat(aws_security_group.elasticache[*].id, [""]), 0),
    element(concat(aws_security_group.alb[*].id, [""]), 0),
    element(concat(aws_security_group.nlb[*].id, [""]), 0)
  ])
}

output "random_passwords" {
  description = "Map of generated random passwords (for reference - not stored as output)"
  value       = {}
  sensitive   = true
}

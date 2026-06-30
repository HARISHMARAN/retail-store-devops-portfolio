resource "aws_kms_key" "secrets" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for ${var.name} secrets encryption"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-secrets-key"
    }
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowKeyAdministrators"
        Effect = "Allow"
        Principal = {
          AWS = length(var.kms_key_administrators) > 0 ? var.kms_key_administrators : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKeyUsers"
        Effect = "Allow"
        Principal = {
          AWS = length(var.kms_key_users) > 0 ? var.kms_key_users : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManager"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "secrets" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.name}-secrets-key"
  target_key_id = aws_kms_key.secrets[0].key_id
}

resource "random_password" "secrets" {
  for_each = var.create_secrets_manager_secrets ? { for k, v in var.secrets : k => v if v.generate_random_password } : {}

  length           = each.value.random_password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "aws_secretsmanager_secret" "this" {
  for_each = var.create_secrets_manager_secrets ? var.secrets : {}

  name                    = "${var.name}-${each.key}"
  description             = each.value.description
  recovery_window_in_days = each.value.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].arn : null

  tags = merge(
    local.tags,
    var.secrets_tags,
    {
      Name = "${var.name}-${each.key}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.create_secrets_manager_secrets ? var.secrets : {}

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.generate_random_password ? jsonencode({ password = random_password.secrets[each.key].result }) : each.value.secret_string_template
}

resource "aws_iam_role" "eks_pod" {
  for_each = var.create_eks_pod_iam_roles ? var.eks_pod_service_accounts : {}

  name = "${var.name}-${each.key}-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_provider_arn, "/^(.*?//)?/", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.key}"
          }
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    var.iam_role_tags,
    {
      Name = "${var.name}-${each.key}-pod-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_pod_managed" {
  for_each = var.create_eks_pod_iam_roles ? var.eks_pod_service_accounts : {}

  role       = aws_iam_role.eks_pod[each.key].name
  policy_arn = length(each.value.policy_arns) > 0 ? each.value.policy_arns[0] : "arn:aws:iam::aws:policy/AWSLambdaBasicExecutionRole"

  depends_on = [aws_iam_role.eks_pod]
}

resource "aws_iam_role_policy" "eks_pod_inline" {
  for_each = var.create_eks_pod_iam_roles ? { for k, v in var.eks_pod_service_accounts : k => v if v.policy_document != "" } : {}

  name   = "${var.name}-${each.key}-inline-policy"
  role   = aws_iam_role.eks_pod[each.key].name
  policy = each.value.policy_document
}

resource "aws_iam_policy" "secrets_access" {
  count = var.create_kms_key && var.create_secrets_manager_secrets ? 1 : 0

  name        = "${var.name}-secrets-access-policy"
  description = "Policy for accessing secrets and KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGetSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.this : secret.arn
        ]
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.secrets[0].arn
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-secrets-access-policy"
    }
  )
}

resource "aws_cloudwatch_log_group" "flow_log" {
  count = var.enable_flow_log && var.create_flow_log_cloudwatch_log_group && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = var.flow_log_cloudwatch_log_group_name != "" ? var.flow_log_cloudwatch_log_group_name : "/aws/vpc/${var.name}/flow-log"
  retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-flow-log"
    }
  )
}

resource "aws_iam_role" "vpc_flow_log" {
  count = var.enable_flow_log && var.create_flow_log_cloudwatch_log_group && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  count = var.enable_flow_log && var.create_flow_log_cloudwatch_log_group && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "flow_log_s3" {
  count = var.enable_flow_log && var.flow_log_destination_type == "s3" && var.flow_log_destination_arn != "" ? 1 : 0

  statement {
    sid     = "AWSLogDeliveryWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${var.flow_log_destination_arn}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0

  log_destination          = var.flow_log_destination_type == "cloud-watch-logs" && element(concat(aws_cloudwatch_log_group.flow_log[*].arn, [""]), 0) != "" ? element(concat(aws_cloudwatch_log_group.flow_log[*].arn, [""]), 0) : var.flow_log_destination_arn
  log_destination_type     = var.flow_log_destination_type
  traffic_type             = var.flow_log_traffic_type
  vpc_id                   = local.vpc_id
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.flow_log_destination_type == "cloud-watch-logs" ? element(concat(aws_iam_role.vpc_flow_log[*].arn, [""]), 0) : null
  max_aggregation_interval = 60

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-flow-log"
    }
  )
}

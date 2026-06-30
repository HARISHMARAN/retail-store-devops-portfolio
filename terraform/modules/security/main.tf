locals {
  tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = var.name
    }
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_wafv2_ip_set" "this" {
  count = var.create_waf_web_acl && length(var.alb_ingress_cidr_blocks) > 0 ? 1 : 0

  name               = "${var.name}-allowed-ips"
  description        = "IP set for allowed IPs"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = [for cidr in var.alb_ingress_cidr_blocks : cidr if cidr != "0.0.0.0/0"]

  tags = merge(
    local.tags,
    var.waf_tags,
    {
      Name = "${var.name}-allowed-ips"
    }
  )
}

resource "aws_wafv2_regex_pattern_set" "this" {
  count = var.create_waf_web_acl ? 1 : 0

  name        = "${var.name}-blocked-paths"
  description = "Regex pattern set for blocked paths"
  scope       = var.waf_scope

  regular_expression = [
    "(?i)^/admin",
    "(?i)^/wp-admin",
    "(?i)^/phpmyadmin",
    "(?i)\\.env$",
    "(?i)\\.git/",
    "(?i)\\.svn/"
  ]

  tags = merge(
    local.tags,
    var.waf_tags,
    {
      Name = "${var.name}-blocked-paths"
    }
  )
}

resource "aws_wafv2_web_acl" "this" {
  count = var.create_waf_web_acl ? 1 : 0

  name        = "${var.name}-web-acl"
  description = "WAF Web ACL for ${var.name}"
  scope       = var.waf_scope

  default_action {
    dynamic "allow" {
      for_each = var.waf_default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.waf_default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.waf_enable_aws_managed_rules ? var.waf_aws_managed_rule_sets : []
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "${var.name}-${rule.value.name}"
        sampled_requests_enabled  = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.waf_enable_rate_limit ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 100

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.waf_rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "${var.name}-rate-limit"
        sampled_requests_enabled  = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.create_waf_web_acl ? [1] : []
    content {
      name     = "BlockMaliciousPaths"
      priority = 200

      action {
        block {}
      }

      statement {
        regex_pattern_set_reference_statement {
          arn = aws_wafv2_regex_pattern_set.this[0].arn

          field_to_match {
            uri_path {}
          }

          text_transformation {
            priority = 0
            type     = "NONE"
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "${var.name}-block-malicious-paths"
        sampled_requests_enabled  = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.create_waf_web_acl && length(aws_wafv2_ip_set.this) > 0 ? [1] : []
    content {
      name     = "GeoBlockRule"
      priority = 300

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.this[0].arn
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "${var.name}-geo-block"
        sampled_requests_enabled  = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.name}-web-acl"
    sampled_requests_enabled  = true
  }

  tags = merge(
    local.tags,
    var.waf_tags,
    {
      Name = "${var.name}-web-acl"
    }
  )
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.create_waf_web_acl ? 1 : 0

  resource_arn = "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.name}-alb"

  web_acl_arn = aws_wafv2_web_acl.this[0].arn
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.create_waf_web_acl ? 1 : 0

  log_destination_configs = [
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/waf/${var.name}"
  ]

  resource_arn = aws_wafv2_web_acl.this[0].arn

  redacted_fields {
    single_header {
      name = "Authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "Cookie"
    }
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  count = var.create_waf_web_acl ? 1 : 0

  name              = "/aws/waf/${var.name}"
  retention_in_days = 90

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-waf-logs"
    }
  )
}

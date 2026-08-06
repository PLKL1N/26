resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project}-cf-acl"
  description = "CloudFront WAF for ${var.project}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "block-abnormal-on-served-paths"
    priority = 2

    action {
      block {}
    }

    statement {
      and_statement {

        statement {
          or_statement {
            dynamic "statement" {
              for_each = var.served_path_prefixes
              content {
                byte_match_statement {
                  search_string         = statement.value
                  positional_constraint = "STARTS_WITH"
                  field_to_match {
                    uri_path {}
                  }
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
            }
          }
        }

        statement {
          not_statement {
            statement {
              and_statement {
                statement {
                  byte_match_statement {
                    search_string         = "requestid="
                    positional_constraint = "CONTAINS"
                    field_to_match {
                      query_string {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
                    }
                  }
                }
                statement {
                  byte_match_statement {
                    search_string         = "uuid="
                    positional_constraint = "CONTAINS"
                    field_to_match {
                      query_string {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-block-abnormal"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.enable_managed_rules ? var.managed_rule_groups : []
    content {
      name     = "aws-${rule.value}"
      priority = 10 + index(var.managed_rule_groups, rule.value)

      override_action {
        count {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project}-${rule.value}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-cf-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project}-cf-acl"
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  count             = var.enable_logging ? 1 : 0
  name              = "aws-waf-logs-${var.project}-cf"
  retention_in_days = var.log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.enable_logging ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [trimsuffix(aws_cloudwatch_log_group.waf[0].arn, ":*")]
}

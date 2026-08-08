resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project}-cf-acl"
  description = "CloudFront WAF for ${var.project}"
  scope       = "CLOUDFRONT"

  default_action {
    block {
      custom_response {
        response_code = 403
      }
    }
  }

  custom_response_body {
    key          = "not-found-404"
    content      = jsonencode({ error = "not found" })
    content_type = "APPLICATION_JSON"
  }

  rule {
    name     = "aws-sqli"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-sqli"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "allow-valid-requests"
    priority = 1
    action {
      allow {}
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
          or_statement {
            statement {
              byte_match_statement {
                search_string         = "requestid"
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
                search_string         = "requestid"
                positional_constraint = "CONTAINS"
                field_to_match {
                  body {
                    oversize_handling = "MATCH"
                  }
                }
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
        statement {
          or_statement {
            statement {
              byte_match_statement {
                search_string         = "uuid"
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
                search_string         = "uuid"
                positional_constraint = "CONTAINS"
                field_to_match {
                  body {
                    oversize_handling = "MATCH"
                  }
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
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-allow-valid"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "not-served-404"
    priority = 2
    action {
      block {
        custom_response {
          response_code            = 404
          custom_response_body_key = "not-found-404"
        }
      }
    }
    statement {
      not_statement {
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
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-not-served-404"
      sampled_requests_enabled   = true
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
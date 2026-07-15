terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = var.web_acl_name
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  custom_response_body {
    key          = "method-not-allowed"
    content      = "Method Not Allowed"
    content_type = "TEXT_PLAIN"
  }

  custom_response_body {
    key          = "access-denied"
    content      = "Access Denied"
    content_type = "TEXT_PLAIN"
  }

  rule {
    name     = "alb-post-only"
    priority = 1

    action {
      block {
        custom_response {
          response_code            = 405
          custom_response_body_key = "method-not-allowed"
        }
      }
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            search_string         = "/v1"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          not_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "POST"
                field_to_match {
                  method {}
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

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "alb-post-only"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "lambda-clientid-format"
    priority = 2

    action {
      block {
        custom_response {
          response_code            = 403
          custom_response_body_key = "access-denied"
        }
      }
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            search_string         = "/reservation"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          size_constraint_statement {
            comparison_operator = "GT"
            size                = 0
            field_to_match {
              single_query_argument {
                name = "client_id"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          not_statement {
            statement {
              regex_match_statement {
                regex_string = "^[A-Za-z][A-Za-z0-9]*[0-9]$"
                field_to_match {
                  single_query_argument {
                    name = "client_id"
                  }
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

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "lambda-clientid-format"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.web_acl_name
    sampled_requests_enabled   = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

resource "random_id" "log_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "cf_logs" {
  bucket        = "${var.project}-cf-logs-${random_id.log_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project}-cf-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred" # ACL 허용 (CF v1 로깅 요구사항)
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = false # 로그 배달 계정 canonical ACL 부여를 위해 false
  ignore_public_acls      = false
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "cf_logs" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cf_logs,
    aws_s3_bucket_public_access_block.cf_logs,
  ]
  bucket = aws_s3_bucket.cf_logs.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }
    # 버킷 소유자 FULL_CONTROL
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    # CloudFront 로그 배달 계정 (전 리전 공통 고정 canonical ID)
    grant {
      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-images-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "rewrite_images" {
  name    = "${var.project}-rewrite-images-prefix"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/functions/rewrite_images.js")
}

resource "aws_cloudfront_cache_policy" "product_get" {
  name        = "${var.project}-product-get"
  min_ttl     = 1
  max_ttl     = 86400
  default_ttl = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["id"]
      }
    }
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_cache_policy" "user_get" {
  name        = "${var.project}-user-get"
  min_ttl     = 0
  max_ttl     = 60
  default_ttl = 20

  parameters_in_cache_key_and_forwarded_to_origin {
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["email"]
      }
    }
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_response_headers_policy" "images_download" {
  name = "${var.project}-images-download"

  custom_headers_config {
    items {
      header   = "Content-Disposition"
      value    = "attachment"
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  depends_on = [aws_s3_bucket_acl.cf_logs]

  enabled     = true
  comment     = "${var.project} unified endpoint (API + static images)"
  price_class = var.price_class

  web_acl_id = var.web_acl_arn != "" ? var.web_acl_arn : null

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "s3-images"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-api"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = var.alb_origin_protocol_policy
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern           = "/v1/product"
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.product_get.id
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern           = "/v1/user"
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.user_get.id
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "s3-images"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.images_download.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_images.arn
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project}-cdn"
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  distribution_id = aws_cloudfront_distribution.this.id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}
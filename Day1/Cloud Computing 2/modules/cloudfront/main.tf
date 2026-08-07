locals {
  s3_origin_id  = "wskorea26-s3-origin"
  alb_origin_id = "wskorea26-alb-origin"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "book_rewrite" {
  name    = "${var.project}-book-path-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "POST /book -> /v1/book rewrite for book app"
  publish = true
  code    = file("${path.module}/functions/book-rewrite.js")
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "wskorea26-concert-cf"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  origin {
    origin_id   = local.alb_origin_id
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port                = 80
      https_port                = 443
      origin_protocol_policy    = "http-only"
      origin_ssl_protocols      = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = "wskorea26-cf"
    }
  }

  origin {
    origin_id                = local.s3_origin_id
    domain_name               = var.s3_bucket_regional_domain_name
    origin_access_control_id  = aws_cloudfront_origin_access_control.s3.id
    origin_path                = "/web/main"

    custom_header {
      name  = "wskorea26-s3-access"
      value = "true"
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods         = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern             = "/book*"
    target_origin_id         = local.alb_origin_id
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods           = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.book_rewrite.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "wskorea26-concert-cf" }
}

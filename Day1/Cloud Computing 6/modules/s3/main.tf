data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_kms" {
  statement {
    sid       = "EnableRoot"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = var.cloudfront_enabled ? [1] : []
    content {
      sid       = "AllowCloudFront"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "AWS:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_kms_key" "s3" {
  description             = "CMK for ${var.project} static S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.s3_kms.json
  tags                    = { Name = "${var.project}-s3-key" }
}

resource "aws_kms_alias" "s3" {
  name          = var.s3_kms_alias
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_s3_bucket" "static" {
  bucket = "${var.project}-static-${var.exam_number}"
  tags   = { Name = "${var.project}-static-${var.exam_number}" }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static" {
  bucket = aws_s3_bucket.static.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_object" "index" {
  bucket                 = aws_s3_bucket.static.id
  key                    = "index.html"
  source                 = "${path.module}/files/index.html"
  content_type           = "text/html"
  source_hash            = filemd5("${path.module}/files/index.html")
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.s3.arn
  depends_on             = [aws_s3_bucket_server_side_encryption_configuration.static]
}

resource "aws_s3_object" "main_image" {
  bucket                 = aws_s3_bucket.static.id
  key                    = "main.jpeg"
  source                 = "${path.module}/files/main.jpeg"
  content_type           = "image/jpeg"
  source_hash            = filemd5("${path.module}/files/main.jpeg")
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.s3.arn
  depends_on             = [aws_s3_bucket_server_side_encryption_configuration.static]
}

data "aws_iam_policy_document" "oac" {
  count = var.cloudfront_enabled ? 1 : 0
  statement {
    sid       = "AllowCloudFrontOAC"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "oac" {
  count      = var.cloudfront_enabled ? 1 : 0
  bucket     = aws_s3_bucket.static.id
  policy     = data.aws_iam_policy_document.oac[0].json
  depends_on = [aws_s3_bucket_public_access_block.static]
}

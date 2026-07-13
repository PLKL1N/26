resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "images" {
  bucket        = "${var.project}-images-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project}-images"
  }
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket                  = aws_s3_bucket.images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# product 어플리케이션(EKS pod)이 이미지를 업로드할 수 있도록 하는 IAM 정책
# EKS IRSA 역할이 생성되면 이 정책의 ARN을 해당 역할에 attach

resource "aws_iam_policy" "product_s3_access" {
  name = "${var.project}-product-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      }
    ]
  })
}

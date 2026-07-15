data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "db_key" {
  statement {
    sid       = "EnableRootPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowDynamoDBService"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.ap-northeast-2.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "db" {
  description             = "CMK for ${var.table_name} DynamoDB table"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.db_key.json

  tags = { Name = "${var.project}-db-key" }
}

resource "aws_kms_alias" "db" {
  name          = var.db_kms_alias
  target_key_id = aws_kms_key.db.key_id
}

resource "aws_dynamodb_table" "books" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "booking_id"

  attribute {
    name = "booking_id"
    type = "S"
  }

  attribute {
    name = "client_id"
    type = "S"
  }

  global_secondary_index {
    name            = "client_id-index"
    hash_key        = "client_id"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.db.arn
  }

  tags = { Name = var.table_name }
}

data "aws_iam_policy_document" "book_write" {
  statement {
    sid    = "BookTableWrite"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:DescribeTable",
    ]
    resources = [
      aws_dynamodb_table.books.arn,
      "${aws_dynamodb_table.books.arn}/index/*",
    ]
  }

  statement {
    sid    = "BookTableKmsUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.db.arn]
  }
}

resource "aws_iam_policy" "book_write" {
  name        = "${var.project}-book-dynamodb-write"
  description = "Allow ONLY the book application to write to the books table"
  policy      = data.aws_iam_policy_document.book_write.json
}

resource "aws_dynamodb_resource_policy" "books_write_restriction" {
  resource_arn = aws_dynamodb_table.books.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyWriteExceptBookApp"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem",
        ]
        Resource = [
          aws_dynamodb_table.books.arn,
          "${aws_dynamodb_table.books.arn}/index/*",
        ]
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-book-dynamodb-role",
              "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${var.project}-book-dynamodb-role/*",
            ]
          }
        }
      }
    ]
  })
}

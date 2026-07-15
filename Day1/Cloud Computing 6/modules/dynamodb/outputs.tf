output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.books.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.books.arn
}

output "gsi_name" {
  description = "GSI name"
  value       = "client_id-index"
}

output "db_kms_key_arn" {
  description = "DynamoDB CMK ARN"
  value       = aws_kms_key.db.arn
}

output "db_kms_alias" {
  description = "DynamoDB CMK alias"
  value       = aws_kms_alias.db.name
}

output "book_write_policy_arn" {
  description = "IAM policy ARN granting book app write access (attach to book SA role later)"
  value       = aws_iam_policy.book_write.arn
}

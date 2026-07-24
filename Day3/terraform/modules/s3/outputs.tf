output "bucket_id" {
  value = aws_s3_bucket.images.id
}

output "bucket_arn" {
  value = aws_s3_bucket.images.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.images.bucket_regional_domain_name
}

output "product_s3_access_policy_arn" {
  description = "product 어플리케이션 역할(IRSA)에 attach할 정책 ARN"
  value       = aws_iam_policy.product_s3_access.arn
}

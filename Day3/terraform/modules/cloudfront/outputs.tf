output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "endpoint" {
  description = "채점 플랫폼에 입력할 엔드포인트 (protocol + address, 경로 없음)"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.this.arn
}

output "log_bucket" {
  description = "CloudFront 액세스 로그가 쌓이는 S3 버킷 이름 (prefix: cloudfront/)"
  value       = aws_s3_bucket.cf_logs.bucket
}
output "endpoint" {
  description = "채점 플랫폼에 입력할 단일 엔드포인트 (enable_cloudfront=true 로 apply한 이후에만 값 존재)"
  value       = var.enable_cloudfront ? module.cloudfront[0].endpoint : null
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_address" {
  value = module.rds.address
}

output "rds_password" {
  value     = module.rds.password
  sensitive = true
}

output "s3_bucket_id" {
  value = module.s3.bucket_id
}

output "bastion_public_ip" {
  description = "Mgmt bastion public IP (SSH 접속용)"
  value       = module.mgmt.bastion_public_ip
}

output "ssh_command" {
  description = "Bastion SSH 명령"
  value       = "ssh -i ${var.project}-key.pem ec2-user@${module.mgmt.bastion_public_ip}"
}

output "gj2026_vpc_id" {
  value = module.vpc.vpc_id
}

output "gj2026_private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}


output "book_repository_url" {
  value = module.ecr.book_repository_url
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "book_write_policy_arn" {
  description = "book 앱(서비스어카운트 역할)에 attach 할 쓰기 정책"
  value       = module.dynamodb.book_write_policy_arn
}

output "eks_kms_alias"     { value = module.eks_kms.eks_kms_alias }
output "s3_bucket_name"    { value = module.s3.bucket_name }
output "s3_kms_alias"      { value = module.s3.s3_kms_alias }
output "access_log_group"  { value = module.cloudwatch.log_group_name }

output "lambda_function_name" { value = module.lambda.function_name }
output "lambda_function_url"  { value = module.lambda.function_url }

output "waf_web_acl_arn" { value = module.waf.web_acl_arn }

output "cloudfront_domain" {
  value = var.enable_cloudfront ? module.cloudfront[0].distribution_domain : null
}

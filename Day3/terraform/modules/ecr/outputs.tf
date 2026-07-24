output "repository_urls" {
  description = "app name -> ECR repository URL"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "app name -> ECR repository ARN"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "registry_id" {
  value = values(aws_ecr_repository.this)[0].registry_id
}

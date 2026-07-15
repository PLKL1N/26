data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "book_repository_url" {
  description = "Book ECR repository URL"
  value       = aws_ecr_repository.book.repository_url
}

output "book_repository_arn" {
  description = "Book ECR repository ARN"
  value       = aws_ecr_repository.book.arn
}

output "registry_id" {
  description = "ECR registry (account) ID"
  value       = aws_ecr_repository.book.registry_id
}

output "ecr_public_cache_prefix" {
  description = "Pull-through cache prefix for public.ecr.aws"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_pull_through_cache_rule.ecr_public.ecr_repository_prefix}"
}

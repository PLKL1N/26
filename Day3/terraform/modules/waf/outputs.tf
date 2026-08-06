output "web_acl_arn" {
  description = "CloudFront distribution 의 web_acl_id 에 넣을 ARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  value = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  value = aws_wafv2_web_acl.this.name
}

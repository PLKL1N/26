variable "project" { type = string }
variable "cdn_name" {
  type    = string
  default = "gj2026-cdn"
}
variable "vpc_origin_name" {
  type    = string
  default = "gj2026-alb-origin"
}
variable "alb_name" {
  type    = string
  default = "gj2026-alb"
}
variable "s3_bucket_regional_domain_name" { type = string }
variable "lambda_function_url_domain" { type = string }
variable "web_acl_arn" { type = string }

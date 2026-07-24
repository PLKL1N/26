variable "project" {
  type = string
}

variable "s3_bucket_id" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "s3_bucket_regional_domain_name" {
  type = string
}

variable "alb_dns_name" {
  description = "EKS Ingress(ALB)의 DNS 이름. root에서 data.aws_lb 조회 결과를 전달받음"
  type        = string
}

variable "alb_origin_protocol_policy" {
  description = "ALB 오리진 프로토콜 정책 (ACM 인증서 붙이기 전까지는 http-only)"
  type        = string
  default     = "http-only"
}

variable "price_class" {
  description = "PriceClass_100(북미/유럽) / PriceClass_200(+아시아,오세아니아) / PriceClass_All"
  type        = string
  default     = "PriceClass_200"
}

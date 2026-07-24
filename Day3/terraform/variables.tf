variable "project" {
  description = "Project name prefix used across all resources"
  type        = string
  default     = "apdev"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "alb_name" {
  description = "콘솔에서 EKS Ingress 생성 시 alb.ingress.kubernetes.io/load-balancer-name 어노테이션으로 고정할 ALB 이름. data.aws_lb 조회에 사용"
  type        = string
  default     = "apdev-alb"
}

variable "enable_cloudfront" {
  description = "ALB(EKS Ingress)가 이미 생성되어 있을 때만 true로 apply. false면 cloudfront/data.aws_lb 조회를 건너뜀"
  type        = bool
  default     = false
}

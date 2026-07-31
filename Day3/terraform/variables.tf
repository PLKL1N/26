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
  description = "ALB 생성후 실행"
  type        = bool
  default     = false
}

variable "enable_cloudwatch" {
  type    = bool
  default = false
}
# ===== CloudWatch 대시보드용 =====
variable "cluster_name" {
  description = "EKS 클러스터명 (Container Insights 차원)"
  type        = string
  default     = "apdev-eks-cluster"
}

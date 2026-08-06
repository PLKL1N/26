variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "alb_arn_suffix" {
  description = "data.aws_lb.app.arn_suffix (예: app/apdev-alb/xxxx)"
  type        = string
}

variable "cluster_name" {
  description = "EKS 클러스터명 (Container Insights 차원)"
  type        = string
}

variable "namespace" {
  description = "앱이 배포된 k8s 네임스페이스"
  type        = string
  default     = "apdev"
}

variable "rds_id" {
  description = "RDS DBInstanceIdentifier"
  type        = string
}

variable "ingress_name" {
  description = "AWS LB Controller Ingress Name"
  type        = string
  default     = "app"
}

variable "cf_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
  default     = ""
}

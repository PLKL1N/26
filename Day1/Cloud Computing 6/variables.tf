variable "project" {
  description = "Project name prefix used across all resources"
  type        = string
  default     = "gj2026"
}

variable "region" {
  description = "AWS Region (Seoul)"
  type        = string
  default     = "ap-northeast-2"
}

variable "exam_number" {
  description = "비번호 입력"
  type        = string
}


variable "enable_cloudfront" {
  description = "12번 CloudFront 생성 여부 (ALB/클러스터가 떠 있을 때 true 로 apply)"
  type        = bool
  default     = false
}

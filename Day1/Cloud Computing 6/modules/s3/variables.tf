variable "project" { type = string }

variable "exam_number" {
  description = "비번호 (S3 bucket suffix: gj2026-static-<비번호>)"
  type        = string
}

variable "s3_kms_alias" {
  type    = string
  default = "alias/gj2026-s3-key"
}

variable "cloudfront_enabled" {
  type    = bool
  default = false
}

variable "cloudfront_distribution_arn" {
  type    = string
  default = null
}

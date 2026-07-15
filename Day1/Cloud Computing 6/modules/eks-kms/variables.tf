variable "project" { type = string }
variable "eks_kms_alias" {
  type    = string
  default = "alias/gj2026-eks-key"
}

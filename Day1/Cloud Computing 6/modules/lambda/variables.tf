variable "project" { type = string }
variable "function_name" {
  type    = string
  default = "gj2026-book-reservation"
}
variable "runtime" {
  type    = string
  default = "python3.14"
}
variable "table_name"     { type = string }
variable "table_arn"      { type = string }
variable "gsi_name"       { type = string }
variable "db_kms_key_arn" { type = string }

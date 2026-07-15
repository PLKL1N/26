variable "project" {
  type = string
}

variable "table_name" {
  description = "DynamoDB table name (spec: books)"
  type        = string
  default     = "books"
}

variable "db_kms_alias" {
  description = "CMK alias for the table (spec: alias/gj2026-db-key)"
  type        = string
  default     = "alias/gj2026-db-key"
}

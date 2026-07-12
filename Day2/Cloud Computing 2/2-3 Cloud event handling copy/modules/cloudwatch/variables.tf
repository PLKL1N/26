variable "project" {
  type = string
}

variable "security_group_id" {
  description = "wsc2026-event-sg id (sg-change-rule 필터용)"
  type        = string
}

variable "instance_id" {
  description = "wsc2026-event-ec2 instance id (terminate/type-change 필터용)"
  type        = string
}

variable "function_arns" {
  description = "Lambda ARNs map keyed by sg/role/terminate/type"
  type        = map(string)
}

variable "function_names" {
  description = "Lambda names map keyed by sg/role/terminate/type"
  type        = map(string)
}

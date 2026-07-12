variable "project" {
  type = string
}

variable "security_group_id" {
  description = "wsc2026-event-sg id (sg-remediation 대상)"
  type        = string
}

variable "instance_id" {
  description = "wsc2026-event-ec2 instance id"
  type        = string
}

variable "ec2_role_name" {
  description = "Instance profile / role name to restore (wsc2026-event-ec2-role)"
  type        = string
}

variable "ec2_role_arn" {
  description = "EC2 role ARN (Lambda iam:PassRole 대상)"
  type        = string
}

variable "instance_type" {
  description = "Original instance type to restore (t3.micro)"
  type        = string
}

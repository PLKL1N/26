variable "keypair_name" {
  description = "EC2 Key Pair Name"
  type        = string
}

variable "instance_name" {
  description = "Bastion instance name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Private subnet ID to launch the management host into"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID for the management host (from vpc module)"
  type        = string
}

variable "instance_profile_name" {
  type = string
}

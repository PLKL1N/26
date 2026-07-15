variable "project" { type = string }

variable "mgmt_vpc_cidr" {
  description = "Management VPC CIDR (must NOT overlap 10.0.0.0/16)"
  type        = string
  default     = "10.99.0.0/16"
}

variable "availability_zones" {
  description = "AZs for mgmt subnets (a, c)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.99.0.0/24", "10.99.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.99.10.0/24", "10.99.11.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "keypair_name"          { type = string }
variable "instance_name"         { type = string }
variable "instance_profile_name" { type = string }

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion. Tighten to your IP/32."
  type        = string
  default     = "0.0.0.0/0"
}

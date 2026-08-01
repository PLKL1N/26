variable "project" {
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.11.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zone"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "Public CIDR block list (2)"
  type        = list(string)
  default     = ["10.11.0.0/24", "10.11.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR block list (2)"
  type        = list(string)
  default     = ["10.11.10.0/24", "10.11.11.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database Subnet CIDR block list (2)"
  type        = list(string)
  default     = ["10.11.20.0/24", "10.11.21.0/24"]
}

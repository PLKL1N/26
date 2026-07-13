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
  default     = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2b"]
}

variable "public_subnet_cidrs" {
  description = "Public CIDR block list (3)"
  type        = list(string)
  default     = ["10.11.0.0/24", "10.11.1.0/24", "10.11.4.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR block list (3)"
  type        = list(string)
  default     = ["10.11.10.0/24", "10.11.11.0/24", "10.11.14.0/24"]
}
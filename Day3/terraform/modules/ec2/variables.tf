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
  default     = "t3.medium"
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch Bastion into"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID for Bastion (from vpc module)"
  type        = string
}

variable "instance_profile_name" {
  type = string
}

variable "root_volume_size" {
  description = "Bastion root EBS volume size (GB)"
  type        = number
  default     = 20
}

variable "src_bucket" {
  description = "src/ 파일이 올라간 S3 버킷"
  type        = string
}

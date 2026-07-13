variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "SG 인바운드 허용 대역 (VPC 내부 전체)"
  type        = string
}

variable "private_subnet_ids" {
  description = "DB Subnet Group에 사용할 프라이빗 서브넷 ID 목록 (서로 다른 AZ, 2개 이상)"
  type        = list(string)
}

variable "db_identifier" {
  type    = string
  default = "apdev-rds-instance"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "gp3 최소 사이즈(GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "논리적인 데이터베이스 이름"
  type        = string
  default     = "dev"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "bastion_public_ip" {
  description = "스키마 생성 시 SSH로 경유할 bastion의 public IP"
  type        = string
}

variable "bastion_ssh_user" {
  type    = string
  default = "ec2-user"
}

variable "bastion_private_key" {
  description = "bastion 접속용 SSH private key (PEM)"
  type        = string
  sensitive   = true
}

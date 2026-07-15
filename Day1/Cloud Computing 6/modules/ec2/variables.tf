variable "keypair_name" {
  description = "EC2 Key Pair name"
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

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID for the bastion"
  type        = string
}

variable "instance_profile_name" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "artifacts_bucket" {
  description = "S3 bucket holding the kubernetes/ deploy artifacts"
  type        = string
}

variable "competitor_number" {
  description = "선수 등록번호 (Grafana 계정용, deploy.sh 기본 인자로 주입)"
  type        = string
}

variable "auto_deploy" {
  description = "true 면 Bastion 부팅 시 EKS 생성 + 워크로드 배포까지 자동 실행"
  type        = bool
  default     = true
}

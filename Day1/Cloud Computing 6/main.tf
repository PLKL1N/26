terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# =========================== VPC ===========================
# Multi-AZ (ap-northeast-1a / 1c). Public subnets host the ALBs created by the
# AWS Load Balancer Controller; private subnets host the EKS node group.
# Subnet tags are required so EKS/ALB controller can auto-discover subnets.
module "vpc" {
  source = "./modules/vpc"

  project      = var.project
  cluster_name = var.cluster_name
  vpc_cidr     = "10.0.0.0/16"

  availability_zones   = ["${var.region}a", "${var.region}c"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.16.0/20", "10.0.32.0/20"]
}

# =========================== IAM ===========================
# Admin role/instance-profile for the bastion so eksctl / kubectl / helm / ECR
# all work from a single host.
module "iam" {
  source        = "./modules/iam"
  instance_name = "${var.project}-bastion"
}

# =========================== ECR ===========================
# Registry for the log-generator container image. EKS nodes pull from here.
module "ecr" {
  source     = "./modules/ecr"
  repo_name  = "${var.project}-app"
}

# =========================== S3 (deploy artifacts) ===========================
# kubernetes/ 폴더를 버킷에 올려두고 Bastion 이 부팅 시 받아갑니다.
module "s3" {
  source         = "./modules/s3"
  project        = var.project
  kubernetes_dir = "${path.root}/kubernetes"
}

# =========================== EC2 (Bastion) ===========================
module "ec2" {
  source = "./modules/ec2"

  instance_name         = "${var.project}-bastion"
  keypair_name          = "${var.project}-key"
  instance_type         = "t3.small"
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  bastion_sg_id         = module.vpc.bastion_sg_id
  instance_profile_name = module.iam.instance_profile_name

  region             = var.region
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  ecr_repository_url = module.ecr.repository_url

  availability_zones = ["${var.region}a", "${var.region}c"]
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  artifacts_bucket  = module.s3.bucket_name
  competitor_number = var.competitor_number
  auto_deploy       = var.auto_deploy

  # S3 객체 업로드가 끝난 뒤 Bastion 이 부팅되도록 보장
  depends_on = [module.s3]
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# =========================== VPC ===========================

module "vpc" { 
  source = "./modules/vpc"

  project              = var.project
  vpc_cidr             = "10.0.0.0/16"

  availability_zones   = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.4.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24", "10.0.5.0/24"]
}


# =========================== EC2 ===========================

module "ec2" {
  source = "./modules/ec2"

  instance_name    = "${var.project}-bastion"
  keypair_name     = "${var.project}-key"
  instance_type    = "t3.medium"
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg_id    = module.vpc.bastion_sg_id
  instance_profile_name = module.iam.instance_profile_name
  src_bucket            = module.file.bucket_id

  depends_on = [module.file, module.s3]
}


# =========================== FILE (src -> S3) ===========================

module "file" {
  source  = "./modules/file"
  project = var.project
}


# =========================== IAM ===========================

module "iam" {
  source        = "./modules/iam"
  instance_name = "${var.project}-bastion"
}


# =========================== ECR ===========================

module "ecr" {
  source = "./modules/ecr"

  project    = var.project
  repo_names = ["user", "product", "stress"]
}


# =========================== RDS ===========================

module "rds" {
  source = "./modules/rds"

  project            = var.project
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  db_identifier      = "apdev-rds-instance"
  db_name            = "dev"

  bastion_public_ip   = module.ec2.bastion_public_ip
  bastion_private_key = module.ec2.private_key_pem
}


# =========================== ALB (EKS Ingress) ===========================

data "aws_lb" "app" {
  count = var.enable_cloudfront ? 1 : 0
  name  = var.alb_name
}


# =========================== S3 (product images) ===========================

module "s3" {
  source  = "./modules/s3"
  project = var.project
}


# =========================== CloudFront ===========================

module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "./modules/cloudfront"

  project                        = var.project
  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name

  alb_dns_name = data.aws_lb.app[0].dns_name
}
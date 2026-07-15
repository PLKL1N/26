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
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"

  project              = var.project
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2b"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  eks_cluster_name     = "${var.project}-eks-cluster"
}

module "iam" {
  source        = "./modules/iam"
  instance_name = "${var.project}-bastion"
}

module "mgmt" {
  source = "./modules/mgmt"

  project               = var.project
  instance_name         = "${var.project}-bastion"
  keypair_name          = "${var.project}-key"
  instance_type         = "t3.small"
  instance_profile_name = module.iam.instance_profile_name

  allowed_ssh_cidr = "0.0.0.0/0"
}

module "ecr" {
  source = "./modules/ecr"

  project              = var.project
  book_repository_name = "book"
}

module "dynamodb" {
  source = "./modules/dynamodb"

  project      = var.project
  table_name   = "books"
  db_kms_alias = "alias/${var.project}-db-key"
}

module "eks_kms" {
  source        = "./modules/eks-kms"
  project       = var.project
  eks_kms_alias = "alias/${var.project}-eks-key"
}

module "cloudwatch" {
  source         = "./modules/cloudwatch"
  project        = var.project
  log_group_name = "/eks/book-svc/access"
}

module "s3" {
  source      = "./modules/s3"
  project            = var.project
  exam_number        = var.exam_number
  cloudfront_enabled = var.enable_cloudfront
}

module "lambda" {
  source = "./modules/lambda"

  project        = var.project
  function_name  = "${var.project}-book-reservation"
  runtime        = "python3.14"
  table_name     = module.dynamodb.table_name
  table_arn      = module.dynamodb.table_arn
  gsi_name       = module.dynamodb.gsi_name
  db_kms_key_arn = module.dynamodb.db_kms_key_arn
}

module "waf" {
  source       = "./modules/waf"
  project      = var.project
  web_acl_name = "${var.project}-waf-acl"

  providers = {
    aws = aws.us_east_1
  }
}

module "cloudfront" {
  source = "./modules/cloudfront"
  count  = var.enable_cloudfront ? 1 : 0

  project                        = var.project
  cdn_name                       = "${var.project}-cdn"
  vpc_origin_name                = "${var.project}-alb-origin"
  alb_name                       = "${var.project}-alb"
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  lambda_function_url_domain     = module.lambda.function_url_domain
  web_acl_arn                    = module.waf.web_acl_arn
}

resource "null_resource" "bootstrap" {
  depends_on = [
    module.vpc,
    module.mgmt,
    module.iam,
    module.ecr,
    module.dynamodb,
    module.eks_kms,
    module.cloudwatch,
    module.s3,
    module.lambda,
  ]

  triggers = {
    bastion_id = module.mgmt.bastion_instance_id
  }

  connection {
    type        = "ssh"
    host        = module.mgmt.bastion_public_ip
    user        = "ec2-user"
    private_key = module.mgmt.bastion_private_key_pem
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "${path.module}/modules/eks"
    destination = "/home/ec2-user"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "sed -i 's/\\r$//' /home/ec2-user/eks/scripts/*.sh",
      "export PATH=/usr/local/bin:/usr/local/sbin:$PATH",
      "chmod +x /home/ec2-user/eks/scripts/*.sh",
      "sudo env \"PATH=$PATH\" bash /home/ec2-user/eks/scripts/cluster-up.sh",
      "sudo env \"PATH=$PATH\" bash /home/ec2-user/eks/scripts/kube-apps.sh",
    ]
  }
}


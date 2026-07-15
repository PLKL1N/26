variable "project" {
  description = "Project name prefix (gj2026)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (Reference01)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs for private subnets (a, b)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (Reference01)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "eks_cluster_name" {
  description = "EKS cluster name used for subnet discovery tags"
  type        = string
  default     = "gj2026-eks-cluster"
}

variable "interface_endpoint_services" {
  description = "Interface VPC endpoint service short names"
  type        = list(string)
  default = [
    "ec2",                 # managed nodegroup / ENI
    "ecr.api",             # ECR auth
    "ecr.dkr",             # ECR image pull
    "sts",                 # IRSA / Pod Identity
    "eks",                 # EKS control plane API
    "eks-auth",            # EKS Pod Identity
    "elasticloadbalancing",# AWS Load Balancer Controller
    "autoscaling",         # managed nodegroup scaling
    "logs",                # CloudWatch Logs (Fluent Bit)
    "monitoring",          # CloudWatch metrics (Grafana datasource)
    "kms",                 # CMK envelope encryption (EKS secret / DynamoDB)
    "ssm",                 # Bottlerocket / Session Manager
    "ssmmessages",
    "ec2messages",
  ]
}

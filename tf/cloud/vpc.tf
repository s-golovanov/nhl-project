data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name                         = "${var.project_name}-k8s-vpc"
  cidr                         = "10.10.0.0/16"
  azs                          = data.aws_availability_zones.available.names
  private_subnets              = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
  public_subnets               = ["10.10.201.0/24", "10.10.202.0/24", "10.10.203.0/24"]
  database_subnets             = ["10.10.251.0/24", "10.10.252.0/24", "10.10.253.0/24"]
  create_database_subnet_group = false
  enable_nat_gateway           = true
  single_nat_gateway           = false
  one_nat_gateway_per_az       = true
  enable_dns_hostnames         = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }

  tags = var.tags
}

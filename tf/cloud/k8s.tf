data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.23.0"

  cluster_name              = var.eks_cluster_name
  cluster_version           = "1.21"
  subnets                   = module.vpc.private_subnets
  enable_irsa               = true
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id = module.vpc.vpc_id

  node_groups = {
    first = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 2
      instance_types   = ["c5a.xlarge"]
      disk_size        = 20
      tags = [
        {
          "key"   = "k8s.io/cluster-autoscaler/enabled"
          "value" = "true"
        },
        {
          "key"   = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
          "value" = "owned"
      }]
    }
  }

  write_kubeconfig       = true
  kubeconfig_output_path = "./"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "eks_fluentbit" {
  name              = "/aws/eks/fluentbit-cloudwatch/logs"
  retention_in_days = 90
}

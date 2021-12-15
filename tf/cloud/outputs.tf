output "project_name" {
  description = "Name of the current project"
  value       = var.project_name
}

output "vpc_name" {
  description = "The name of the VPC specified as argument to this module"
  value       = module.vpc.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of CIDR of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks.*
}

output "public_subnets" {
  description = "List of CIDR of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks.*
}

output "database_subnets" {
  description = "List of CIDR of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks.*
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips.*
}

output "app_prod_mysql_cluster_endpoint" {
  description = "Writer endpoint for the app cluster db"
  value       = module.app_prod_aurora_mysql.cluster_endpoint
}

output "app_prod_mysql_cluster_engine_version_actual" {
  description = "The running version of the app cluster database"
  value       = module.app_prod_aurora_mysql.cluster_engine_version_actual
}

output "app_prod_mysql_cluster_database_name" {
  description = "Name for an automatically created app database on cluster creation"
  value       = module.app_prod_aurora_mysql.cluster_database_name
}

output "app_test_mysql_cluster_endpoint" {
  description = "Writer endpoint for the app cluster db"
  value       = module.app_test_aurora_mysql.cluster_endpoint
}

output "app_test_mysql_cluster_engine_version_actual" {
  description = "The running version of the app cluster database"
  value       = module.app_test_aurora_mysql.cluster_engine_version_actual
}

output "app_test_mysql_cluster_database_name" {
  description = "Name for an automatically created app database on cluster creation"
  value       = module.app_test_aurora_mysql.cluster_database_name
}

output "sonarqube_postgresql_cluster_endpoint" {
  description = "Writer endpoint for the sonarqube cluster db"
  value       = module.sonarqube_aurora_postgresql.cluster_endpoint
}

output "sonarqube_postgresql_cluster_engine_version_actual" {
  description = "The running version of the sonarqube cluster database"
  value       = module.sonarqube_aurora_postgresql.cluster_engine_version_actual
}

output "sonarqube_postgresql_cluster_database_name" {
  description = "Name for an automatically created sonarqube database on cluster creation"
  value       = module.sonarqube_aurora_postgresql.cluster_database_name
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = var.eks_cluster_name
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_url" {
  description = "EKS OIDC"
  value       = module.eks.cluster_oidc_issuer_url
}
/*
output "eks_alb_sg_name" {
  description = "Security group name for EKS ALBs"
  value       = aws_security_group.eks_alb_sg.name
}

output "eks_alb_sg_id" {
  description = "Security group id for EKS ALBs"
  value       = aws_security_group.eks_alb_sg.id
}
*/
output "efs_name" {
  description = "EFS name"
  value       = aws_efs_file_system.efs_fs.creation_token
}

output "efs_id" {
  description = "EFS ID"
  value       = aws_efs_file_system.efs_fs.id
}

output "efs_dns_name" {
  description = "EFS DNS Name"
  value       = aws_efs_file_system.efs_fs.dns_name
}

output "ecr_repository_url" {
  description = "The URL of ECR repositories"
  value       = aws_ecr_repository.repo.*.repository_url
}

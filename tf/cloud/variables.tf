variable "project_name" {
  type        = string
  description = "Project name"
  default     = "projectname"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "my-cluster"
}

variable "app_prod_database_name" {
  type        = string
  description = "RDS Aurora serverless app prod database name"
  default     = "appdbnameone"
}

variable "app_test_database_name" {
  type        = string
  description = "RDS Aurora serverless app test database name"
  default     = "appdbnametwo"
}

variable "sonarqube_database_name" {
  type        = string
  description = "RDS Aurora serverless sonarqube database name"
  default     = "sonardbname"
}

variable "efs_throughput" {
  type        = string
  description = "EFS throughput in mibps"
  default     = "100"
}

variable "tags" {
  type = object({
    Owner       = string
    Environment = string
  })

  description = "Tags for cloud objects of the project"
  default = {
    Owner       = "ProjectOwner"
    Environment = "ProjectEnv"
  }
}

variable "ecr_repositories" {
  description = "ECR repo list"
  type        = list(any)
  default     = ["backend-app", "init", "get-static"]
}

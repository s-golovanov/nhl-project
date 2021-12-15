resource "aws_cloudwatch_log_group" "app_prod_db_error" {
  name              = "/aws/rds/cluster/${var.project_name}-app-prod-mysql/error"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "app_prod_db_general" {
  name              = "/aws/rds/cluster/${var.project_name}-app-prod-mysql/general"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "app_prod_db_slowquery" {
  name              = "/aws/rds/cluster/${var.project_name}-app-prod-mysql/slowquery"
  retention_in_days = 90
}

resource "random_password" "app_prod_db_root_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "app_prod_db_root_password" {
  name        = "${var.project_name}_app_prod_db_root_password"
  description = "root password for app-prod-mysql-db"
  type        = "SecureString"
  value       = random_password.app_prod_db_root_password.result
}

resource "aws_rds_cluster_parameter_group" "app_prod_mysql" {
  name        = "${var.project_name}-aurora-app-prod-mysql-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "aurora app prod mysql cluster parameter group"
  tags        = var.tags

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "5"
  }
}

module "app_prod_aurora_mysql" {
  depends_on = [
    resource.aws_cloudwatch_log_group.app_prod_db_error, resource.aws_cloudwatch_log_group.app_prod_db_general, resource.aws_cloudwatch_log_group.app_prod_db_slowquery
  ]

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.1.3"

  name              = "${var.project_name}-app-prod-mysql"
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.database_subnets
  create_security_group = true
  allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  create_random_password = false
  master_password        = aws_ssm_parameter.app_prod_db_root_password.value

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.app_prod_mysql.id
  database_name                   = var.app_prod_database_name

  scaling_configuration = {
    auto_pause               = false
    min_capacity             = 1
    max_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "app_test_db_error" {
  name              = "/aws/rds/cluster/${var.project_name}-app-test-mysql/error"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "app_test_db_general" {
  name              = "/aws/rds/cluster/${var.project_name}-app-test-mysql/general"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "app_test_db_slowquery" {
  name              = "/aws/rds/cluster/${var.project_name}-app-test-mysql/slowquery"
  retention_in_days = 90
}

resource "random_password" "app_test_db_root_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "app_test_db_root_password" {
  name        = "${var.project_name}_app_test_db_root_password"
  description = "root password for app-test-mysql-db"
  type        = "SecureString"
  value       = random_password.app_test_db_root_password.result
}

resource "aws_rds_cluster_parameter_group" "app_test_mysql" {
  name        = "${var.project_name}-aurora-app-test-mysql-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "aurora app test mysql cluster parameter group"
  tags        = var.tags

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "5"
  }
}

module "app_test_aurora_mysql" {
  depends_on = [
    resource.aws_cloudwatch_log_group.app_test_db_error, resource.aws_cloudwatch_log_group.app_test_db_general, resource.aws_cloudwatch_log_group.app_test_db_slowquery
  ]

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.1.3"

  name              = "${var.project_name}-app-test-mysql"
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.database_subnets
  create_security_group = true
  allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  create_random_password = false
  master_password        = aws_ssm_parameter.app_test_db_root_password.value

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.app_test_mysql.id
  database_name                   = var.app_test_database_name

  scaling_configuration = {
    auto_pause               = false
    min_capacity             = 1
    max_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "sonarqube_db" {
  name              = "/aws/rds/cluster/${var.project_name}-sonarqube-postgresql/postgresql"
  retention_in_days = 90
}

resource "random_password" "sonarqube_db_root_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "sonarqube_db_root_password" {
  name        = "${var.project_name}-sonarqube-db-root-password"
  description = "root password for sonarqube-postgresql-db"
  type        = "SecureString"
  value       = random_password.sonarqube_db_root_password.result
}

resource "aws_rds_cluster_parameter_group" "sonarqube_postgresql" {
  name        = "${var.project_name}-aurora-sonarqube-postgresql-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "aurora sonarqube postgresql cluster parameter group"
  tags        = var.tags

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "5000"
  }

}

module "sonarqube_aurora_postgresql" {
  depends_on = [
    resource.aws_cloudwatch_log_group.sonarqube_db
  ]

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.1.3"

  name              = "${var.project_name}-sonarqube-postgresql"
  engine            = "aurora-postgresql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.database_subnets
  create_security_group = true
  allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  create_random_password = false
  master_password        = aws_ssm_parameter.sonarqube_db_root_password.value

  db_cluster_parameter_group_name = resource.aws_rds_cluster_parameter_group.sonarqube_postgresql.id
  database_name                   = var.sonarqube_database_name

  scaling_configuration = {
    auto_pause               = false
    min_capacity             = 2
    max_capacity             = 4
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = var.tags
}

locals {
  k8s_namespace_sq          = resource.kubernetes_namespace.sonarqube.metadata[0].name
  k8s_chart_release_name_sq = "sonarqube"
}

resource "random_password" "sonarqube_admin_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "sonarqube_admin_password" {
  name        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-sonarqube-admin-password"
  description = "SonarQube admin password"
  type        = "SecureString"
  value       = random_password.sonarqube_admin_password.result
}

data "aws_ssm_parameter" "sonarqube-db-root-password" {
  name = "${data.terraform_remote_state.cloud.outputs.project_name}-sonarqube-db-root-password"
}

resource "helm_release" "sonarqube" {
  depends_on = [
    resource.helm_release.aws_efs_csi_driver
  ]

  name       = local.k8s_chart_release_name_sq
  namespace  = local.k8s_namespace_sq
  repository = "https://oteemo.github.io/charts"
  chart      = "sonarqube"
  version    = "9.9.0"

  set {
    name  = "image.tag"
    value = "9.2.0-community"
  }

  set {
    name  = "account.adminPassword"
    value = resource.aws_ssm_parameter.sonarqube_admin_password.value
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClass"
    value = "efs-sc"
  }

  set {
    name  = "persistence.accessMode"
    value = "ReadWriteMany"
  }

  set {
    name  = "persistence.size"
    value = "12Gi"
  }

  set {
    name  = "containerSecurityContext.runAsUser"
    value = "0"
  }

  set {
    name  = "postgresql.enabled"
    value = "false"
  }

  set {
    name  = "postgresql.postgresqlServer"
    value = data.terraform_remote_state.cloud.outputs.sonarqube_postgresql_cluster_endpoint
  }

  set {
    name  = "postgresql.postgresqlUsername"
    value = "root"
  }

  set {
    name  = "postgresql.postgresqlPassword"
    value = data.aws_ssm_parameter.sonarqube-db-root-password.value
  }

  set {
    name  = "postgresql.postgresqlDatabase"
    value = data.terraform_remote_state.cloud.outputs.sonarqube_postgresql_cluster_database_name
  }

  set {
    name  = "postgresql.service.port"
    value = "5432"
  }

}

locals {
  k8s_namespace_je            = resource.kubernetes_namespace.jenkins.metadata[0].name
  k8s_service_account_name_je = "jenkins"
  k8s_chart_release_name_je   = "jenkins"
}

resource "random_password" "jenkins_admin_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "jenkins_admin_password" {
  name        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-jenkins-admin-password"
  description = "Jenkins Admin Password"
  type        = "SecureString"
  value       = random_password.jenkins_admin_password.result
}

resource "helm_release" "jenkins" {
  depends_on = [
    resource.helm_release.aws_efs_csi_driver
  ]

  name       = local.k8s_chart_release_name_je
  namespace  = local.k8s_namespace_je
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "3.8.9"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.k8s_service_account_name_je
  }

  set {
    name  = "controller.adminPassword"
    value = resource.aws_ssm_parameter.jenkins_admin_password.value
  }

  values = [
    "${file("jenkins-values.yaml")}"
  ]

}

resource "kubernetes_role_binding" "jenkins_prod" {
  depends_on = [
    resource.helm_release.jenkins
  ]

  metadata {
    name      = "jenkins-prod"
    namespace = resource.kubernetes_namespace.prod.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:${local.k8s_service_account_name_je}"
    namespace = local.k8s_namespace_je
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_binding" "jenkins_test" {
  depends_on = [
    resource.helm_release.jenkins
  ]

  metadata {
    name      = "jenkins-test"
    namespace = resource.kubernetes_namespace.test.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:${local.k8s_service_account_name_je}"
    namespace = local.k8s_namespace_je
    api_group = "rbac.authorization.k8s.io"
  }
}

locals {
  k8s_namespace_ps          = resource.kubernetes_namespace.monitoring.metadata[0].name
  k8s_chart_release_name_ps = "kube-prometheus-stack"
}

resource "random_password" "grafana_admin_password" {
  length           = 12
  special          = true
  override_special = "!#$%"
}

resource "aws_ssm_parameter" "grafana_admin_password" {
  name        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-grafana-admin-password"
  description = "Grafana Admin Password"
  type        = "SecureString"
  value       = random_password.grafana_admin_password.result
}

resource "helm_release" "kube_prometheus_stack" {
  depends_on = [
    resource.helm_release.aws_efs_csi_driver
  ]

  name       = local.k8s_chart_release_name_ps
  namespace  = local.k8s_namespace_ps
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "20.0.1"

  set {
    name  = "grafana.adminPassword"
    value = resource.aws_ssm_parameter.grafana_admin_password.value
  }

  values = [
    "${file("promstack-values.yaml")}"
  ]

}

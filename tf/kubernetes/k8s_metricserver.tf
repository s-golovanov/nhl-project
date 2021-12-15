locals {
  k8s_namespace_ms          = "kube-system"
  k8s_chart_release_name_ms = "metric-server"
}

resource "helm_release" "metric_server" {

  name       = local.k8s_chart_release_name_ms
  namespace  = local.k8s_namespace_ms
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.6.0"

  set {
    name  = "args"
    value = "{${join(",", var.args)}}"
  }
}

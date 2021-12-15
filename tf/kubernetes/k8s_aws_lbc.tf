locals {
  k8s_namespace_lbc            = "kube-system"
  k8s_service_account_name_lbc = "aws-load-balancer-controller"
  k8s_chart_release_name_lbc   = "aws-load-balancer-controller"
  lb_name_parts                = split("-", split(".", kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname).0)
}

resource "helm_release" "aws_load_balancer_controller" {

  depends_on = [
    resource.aws_iam_role_policy_attachment.aws_load_balancer_controller_role_attachment
  ]

  name       = local.k8s_chart_release_name_lbc
  namespace  = local.k8s_namespace_lbc
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.3.2"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.k8s_service_account_name_lbc
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.cloud.outputs.eks_cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = resource.aws_iam_role.aws_load_balancer_controller_role.arn
    type  = "string"
  }
}

data "aws_iam_policy_document" "assume_role_with_oidc_lbc" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.terraform_remote_state.cloud.outputs.eks_cluster_oidc_url, "https://", "")}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.cloud.outputs.eks_cluster_oidc_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.k8s_namespace_lbc}:${local.k8s_service_account_name_lbc}"]
    }
  }
}

data "aws_iam_policy_document" "aws_load_balancer_controller" {

  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"

      values = [
        "elasticloadbalancing.amazonaws.com"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateSecurityGroup"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:security-group/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateSecurityGroup"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:security-group/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "true"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "true"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_role" "aws_load_balancer_controller_role" {
  name_prefix        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-lbc-role"
  description        = "AWS Load Balancer Controller role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_with_oidc_lbc.json
  path               = "/"
  tags               = var.tags
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name_prefix = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-lbc-policy"
  description = "AWS Load Balancer Controller policy"
  policy      = data.aws_iam_policy_document.aws_load_balancer_controller.json
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_role_attachment" {
  role       = aws_iam_role.aws_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
}


resource "kubernetes_ingress" "aws_ingress_prod" {
  depends_on = [
    resource.helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-ingress-prod"
    namespace = resource.kubernetes_namespace.prod.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.amazon_issued.arn
      "alb.ingress.kubernetes.io/group.name"           = "group"
      "alb.ingress.kubernetes.io/group.order"          = "10"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/ip-address-type"      = "ipv4"
      "alb.ingress.kubernetes.io/listen-ports"         = <<JSON
[
  {"HTTP": 80},
  {"HTTPS": 443}
]
JSON
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = <<JSON
{
  "Type": "redirect",
  "RedirectConfig": {
    "Protocol": "HTTPS",
    "Port": "443",
    "StatusCode": "HTTP_301"
  }
}
JSON
    }
  }

  spec {
    rule {
      host = var.site_fqdn
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = var.prod_env_svc_front_app
            service_port = 80
          }
          path = "/*"
        }
      }
    }
    rule {
      host = "www.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = var.prod_env_svc_front_app
            service_port = 80
          }
          path = "/*"
        }
      }
    }
  }

  wait_for_load_balancer = true
}

resource "kubernetes_ingress" "aws_ingress_test" {
  depends_on = [
    resource.helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-ingress-test"
    namespace = resource.kubernetes_namespace.test.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.amazon_issued.arn
      "alb.ingress.kubernetes.io/group.name"           = "group"
      "alb.ingress.kubernetes.io/group.order"          = "20"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/ip-address-type"      = "ipv4"
      "alb.ingress.kubernetes.io/listen-ports"         = <<JSON
[
  {"HTTP": 80},
  {"HTTPS": 443}
]
JSON
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = <<JSON
{
  "Type": "redirect",
  "RedirectConfig": {
    "Protocol": "HTTPS",
    "Port": "443",
    "StatusCode": "HTTP_301"
  }
}
JSON
    }
  }

  spec {
    rule {
      host = "t.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = var.test_env_svc_front_app
            service_port = 80
          }
          path = "/*"
        }
      }
    }
  }

  wait_for_load_balancer = true
}

resource "kubernetes_ingress" "aws_ingress_jenkins" {
  depends_on = [
    resource.helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-ingress-jenkins"
    namespace = resource.kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.amazon_issued.arn
      "alb.ingress.kubernetes.io/group.name"           = "group"
      "alb.ingress.kubernetes.io/group.order"          = "30"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/ip-address-type"      = "ipv4"
      "alb.ingress.kubernetes.io/listen-ports"         = <<JSON
[
  {"HTTP": 80},
  {"HTTPS": 443}
]
JSON
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = <<JSON
{
  "Type": "redirect",
  "RedirectConfig": {
    "Protocol": "HTTPS",
    "Port": "443",
    "StatusCode": "HTTP_301"
  }
}
JSON
    }
  }

  spec {
    rule {
      host = "j.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = local.k8s_chart_release_name_je
            service_port = 8080
          }
          path = "/*"
        }
      }
    }
  }

  wait_for_load_balancer = true
}

resource "kubernetes_ingress" "aws_ingress_monitoring" {
  depends_on = [
    resource.helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-ingress-monitoring"
    namespace = resource.kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.amazon_issued.arn
      "alb.ingress.kubernetes.io/group.name"           = "group"
      "alb.ingress.kubernetes.io/group.order"          = "40"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/ip-address-type"      = "ipv4"
      "alb.ingress.kubernetes.io/listen-ports"         = <<JSON
[
  {"HTTP": 80},
  {"HTTPS": 443}
]
JSON
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = <<JSON
{
  "Type": "redirect",
  "RedirectConfig": {
    "Protocol": "HTTPS",
    "Port": "443",
    "StatusCode": "HTTP_301"
  }
}
JSON
    }
  }

  spec {
    rule {
      host = "g.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = "${local.k8s_chart_release_name_ps}-grafana"
            service_port = 80
          }
          path = "/*"
        }
      }
    }
    rule {
      host = "p.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = "${local.k8s_chart_release_name_ps}-prometheus"
            service_port = 9090
          }
          path = "/*"
        }
      }
    }
  }

  wait_for_load_balancer = true
}



resource "kubernetes_ingress" "aws_ingress_sonarqube" {
  depends_on = [
    resource.helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-ingress-sonarqube"
    namespace = resource.kubernetes_namespace.sonarqube.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.amazon_issued.arn
      "alb.ingress.kubernetes.io/group.name"           = "group"
      "alb.ingress.kubernetes.io/group.order"          = "50"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/ip-address-type"      = "ipv4"
      "alb.ingress.kubernetes.io/listen-ports"         = <<JSON
[
  {"HTTP": 80},
  {"HTTPS": 443}
]
JSON
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = <<JSON
{
  "Type": "redirect",
  "RedirectConfig": {
    "Protocol": "HTTPS",
    "Port": "443",
    "StatusCode": "HTTP_301"
  }
}
JSON
    }
  }

  spec {
    rule {
      host = "s.${var.site_fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
          path = "/*"
        }
        path {
          backend {
            service_name = "${local.k8s_chart_release_name_sq}-sonarqube"
            service_port = 9000
          }
          path = "/*"
        }
      }
    }
  }

  wait_for_load_balancer = true
}

data "aws_route53_zone" "zone" {
  name         = var.site_fqdn
  private_zone = false
}


data "aws_lb" "aws_ingress" {
  name = join("-", slice(local.lb_name_parts, 0, length(local.lb_name_parts) - 1))
}

resource "aws_route53_record" "prod" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.site_fqdn
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "prod_www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "www.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "test" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "t.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "j.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "g.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "prometheus" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "p.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sonarqube" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "s.${var.site_fqdn}"
  type    = "A"
  alias {
    name                   = kubernetes_ingress.aws_ingress_prod.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.aws_ingress.zone_id
    evaluate_target_health = false
  }
}

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.site_fqdn
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}

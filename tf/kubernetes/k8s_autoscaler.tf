locals {
  k8s_namespace_as            = "kube-system"
  k8s_service_account_name_as = "cluster-autoscaler"
  k8s_chart_release_name_as   = "cluster-autoscaler"
}


resource "helm_release" "cluster_autoscaler" {

  depends_on = [
    resource.aws_iam_role_policy_attachment.cluster_autoscaler_role_attachment
  ]

  name       = local.k8s_chart_release_name_as
  namespace  = local.k8s_namespace_as
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.10.8"

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = local.k8s_service_account_name_as
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = resource.aws_iam_role.cluster_autoscaler_role.arn
    type  = "string"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = data.terraform_remote_state.cloud.outputs.eks_cluster_name
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "5m"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "5m"
  }

}

data "aws_iam_policy_document" "assume_role_with_oidc_as" {

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
      values   = ["system:serviceaccount:${local.k8s_namespace_as}:${local.k8s_service_account_name_as}"]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${data.terraform_remote_state.cloud.outputs.eks_cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler_role" {
  name               = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-cluster-autoscaler-role"
  description        = "EKS cluster autoscaler role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_with_oidc_as.json
  path               = "/"
  tags               = var.tags
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-cluster-autoscaler-policy"
  description = "EKS cluster autoscaler policy"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_role_attachment" {
  role       = aws_iam_role.cluster_autoscaler_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

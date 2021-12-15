locals {
  k8s_namespace_fb            = resource.kubernetes_namespace.logging.metadata[0].name
  k8s_service_account_name_fb = "aws-fluent-bit"
  k8s_chart_release_name_fb   = "aws-fluent-bit"
}


resource "helm_release" "aws_fluent_bit" {

  depends_on = [
    resource.aws_iam_role_policy_attachment.aws_fluent_bit_role_attachment
  ]

  name       = local.k8s_chart_release_name_fb
  namespace  = local.k8s_namespace_fb
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.11"

  set {
    name  = "cloudWatch.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "cloudWatch.logRetentionDays"
    value = "90"
  }

  set {
    name  = "firehose.enabled"
    value = "false"
  }

  set {
    name  = "kinesis.enabled"
    value = "false"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.k8s_service_account_name_fb
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = resource.aws_iam_role.aws_fluent_bit_role.arn
    type  = "string"
  }
}

data "aws_iam_policy_document" "assume_role_with_oidc_fb" {

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
      values   = ["system:serviceaccount:${local.k8s_namespace_fb}:${local.k8s_service_account_name_fb}"]
    }
  }
}

data "aws_iam_policy_document" "aws_fluent_bit" {
  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "aws_fluent_bit_role" {
  name_prefix        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-fluent-bit-role"
  description        = "EKS fluent bit role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_with_oidc_fb.json
  path               = "/"
  tags               = var.tags
}

resource "aws_iam_policy" "aws_fluent_bit_policy" {
  name_prefix = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-aws-fluent-bit-policy"
  description = "EKS fluent bit policy"
  policy      = data.aws_iam_policy_document.aws_fluent_bit.json
}


resource "aws_iam_role_policy_attachment" "aws_fluent_bit_role_attachment" {
  role       = aws_iam_role.aws_fluent_bit_role.name
  policy_arn = aws_iam_policy.aws_fluent_bit_policy.arn
}

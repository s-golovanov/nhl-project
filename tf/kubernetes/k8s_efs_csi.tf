locals {
  k8s_namespace_csi            = "kube-system"
  k8s_service_account_name_csi = "aws-efs-csi-driver"
  k8s_chart_release_name_csi   = "aws-efs-csi-driver"
}


resource "helm_release" "aws_efs_csi_driver" {

  depends_on = [
    resource.aws_iam_role_policy_attachment.efs_csi_driver_role_attachment
  ]

  name       = local.k8s_chart_release_name_csi
  namespace  = local.k8s_namespace_csi
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  version    = "2.2.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = local.k8s_service_account_name_csi
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = resource.aws_iam_role.efs_csi_driver_role.arn
    type  = "string"
  }

  set {
    name  = "node.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "node.serviceAccount.name"
    value = local.k8s_service_account_name_csi
  }

  set {
    name  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = resource.aws_iam_role.efs_csi_driver_role.arn
    type  = "string"
  }

  set {
    name  = "storageClasses[0].name"
    value = "efs-sc"
  }

  set {
    name  = "storageClasses[0].mountOptions[0]"
    value = "tls"
  }

  set {
    name  = "storageClasses[0].parameters.provisioningMode"
    value = "efs-ap"
  }

  set {
    name  = "storageClasses[0].parameters.fileSystemId"
    value = data.terraform_remote_state.cloud.outputs.efs_id
  }

  set {
    name  = "storageClasses[0].parameters.directoryPerms"
    value = "700"
    type  = "string"
  }

  set {
    name  = "storageClasses[0].parameters.gidRangeStart"
    value = "1000"
    type  = "string"
  }

  set {
    name  = "storageClasses[0].parameters.gidRangeEnd"
    value = "2000"
    type  = "string"
  }

  set {
    name  = "storageClasses[0].parameters.basePath"
    value = "/efs-csi-dynamic"
  }

  set {
    name  = "storageClasses[0].provisioner"
    value = "efs.csi.aws.com"
  }

  set {
    name  = "storageClasses[0].reclaimPolicy"
    value = "Delete"
  }

  set {
    name  = "storageClasses[0].volumeBindingMode"
    value = "Immediate"
  }
}

data "aws_iam_policy_document" "assume_role_with_oidc_csi" {

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
      values   = ["system:serviceaccount:${local.k8s_namespace_csi}:${local.k8s_service_account_name_csi}"]
    }
  }
}

data "aws_iam_policy_document" "efs_csi_driver" {

  statement {
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "efs_csi_driver_role" {
  name_prefix        = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-efs-csi-driver-role"
  description        = "EKS EFS CSI Driver role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_with_oidc_csi.json
  path               = "/"
  tags               = var.tags
}

resource "aws_iam_policy" "efs_csi_driver_policy" {
  name_prefix = "${data.terraform_remote_state.cloud.outputs.eks_cluster_id}-efs-csi-driver-policy"
  description = "EKS EFS CSI Driver policy"
  policy      = data.aws_iam_policy_document.efs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver_role_attachment" {
  role       = aws_iam_role.efs_csi_driver_role.name
  policy_arn = aws_iam_policy.efs_csi_driver_policy.arn
}

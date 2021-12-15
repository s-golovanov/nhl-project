resource "aws_ecr_repository" "repo" {
  count = length(var.ecr_repositories)

  name                 = "${var.project_name}-${element(var.ecr_repositories, count.index)}"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {

    encryption_type = "KMS"

  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "cleanup_policies" {
  count = length(var.ecr_repositories)

  repository = element(aws_ecr_repository.repo.*.name, count.index)
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 20 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 20
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

data "aws_iam_policy" "ecr_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_access_key" "ecr_user_key" {
  user = aws_iam_user.ecr_user.name
}

resource "aws_iam_user" "ecr_user" {
  name = "${var.project_name}-ecr-user"
  path = "/"
}

resource "aws_iam_policy_attachment" "attach_ecr_policy" {
  name       = "${var.project_name}-ecr-policy-attach"
  users      = [aws_iam_user.ecr_user.name]
  policy_arn = data.aws_iam_policy.ecr_policy.arn
}

resource "aws_ssm_parameter" "ecr_user_access_key" {
  name        = "${var.project_name}-ecr-user-access-key"
  description = "ECR repo access key"
  type        = "SecureString"
  value       = aws_iam_access_key.ecr_user_key.id
}

resource "aws_ssm_parameter" "ecr_user_secret_key" {
  name        = "${var.project_name}-ecr-user-secret-key"
  description = "ECR repo secret key"
  type        = "SecureString"
  value       = aws_iam_access_key.ecr_user_key.secret
}

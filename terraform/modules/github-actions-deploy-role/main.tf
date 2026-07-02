locals {
  oidc_subject = "repo:${var.github_repository}:environment:${var.github_environment}"
}

data "aws_iam_policy_document" "assume_role" {
  count = var.create ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.oidc_subject]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.create ? 1 : 0
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "this" {
  count = var.create ? 1 : 0
  name  = "${var.name}-policy"
  role  = aws_iam_role.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EcrAuthorization"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "EcrImagePushAndScan"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImageScanFindings",
          "ecr:DescribeImages",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:StartImageScan",
          "ecr:UploadLayerPart"
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Sid    = "EcsDescribe"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "EcsDeploy"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "EcsServiceUpdate"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService"
        ]
        Resource = var.service_arns
      },
      {
        Sid    = "PassOnlyEcsRoles"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = concat([var.task_execution_role_arn], var.task_role_arns)
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

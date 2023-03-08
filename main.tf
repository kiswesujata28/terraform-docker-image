terraform {
  required_version = ">=v0.12.20"

  backend "s3" {
    encrypt = true
    acl     = "private"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

## IAM user

resource "aws_iam_user" "testuser" {
  count = var.enabled ? 1 : 0

  name                 = var.user_name
  force_destroy        = var.force_destroy
  path                 = var.path
  permissions_boundary = var.permissions_boundary
  tags                 = var.tags
}

## IAM access keys

resource "aws_iam_access_key" "test_access_key" {
  count   = var.enabled ? 1 : 0
  user    = aws_iam_user.test_user.*.name[0]
  pgp_key = var.pgp_key
  status  = var.status
}

## IAM user login profile
resource "aws_iam_user_login_profile" "test_login_profile" {
  count                   = var.create_user && var.create_iam_user_login_profile ? 1 : 0
  user                    = aws_iam_user.test_user[0].name
  password_length         = var.password_length
  password_reset_required = var.password_reset_required
}

## SSH Key
resource "aws_iam_user_ssh_key" "test_user_key" {
  count      = var.create_user && var.upload_iam_user_ssh_key ? 1 : 0
  username   = aws_iam_user.test_user[0].name
  encoding   = var.ssh_key_encoding
  public_key = var.ssh_public_key
}


## Secrets manager
resource "aws_secretsmanager_secret" "test_user_secret" {
  name = var.user_name
}

## Secrets manager
resource "aws_secretsmanager_secret_version" "test_user_secret_version" {
  secret_id     = aws_secretsmanager_secret.test_user_secret.id
  secret_string = <<EOF
  {
    "username": "${join("", aws_iam_user.test_user.*.name)}"
    "password": "${join("", aws_iam_user_login_profile.test_login_profile.*.password)}" 
    "Keyid":  "${join("", aws_iam_access_key.test_access_key.*.id)}" 
    "secretaccesskey": "${join("", aws_iam_access_key.test_access_key.*.secret)}"
  }
EOF
}

# IAM Policy
data "aws_iam_policy_document" "test_user_policy_document" {
  count = var.enabled ? 1 : 0
  statement {
    sid    = "GetSecretValueForParticularUser"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      "arn:aws:secretsmanager:us-east-1:046393842099:secret:$${aws:username}*"
    ]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:username"
      values   = ["$${aws:username}"]

    }

  }

  statement {
    sid    = "ListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetRandomPassword",
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:username"
      values   = ["$${aws:username}"]

    }

  }
}

resource "aws_iam_policy" "test_user_policy" {
  name        = "user-specific-secrets-manager-policy"
  description = "user specific secretts manager policy"
  policy      = data.aws_iam_policy_document.test_user_policy_document[0].json
}

# Attach Secrets manager policy to the user
resource "aws_iam_user_policy_attachment" "test_user_Policy_attach" {
  user       = aws_iam_user.test_user[0].name
  policy_arn = aws_iam_policy.test_user_policy.arn
}


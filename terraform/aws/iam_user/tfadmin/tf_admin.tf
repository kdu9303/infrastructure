###############################################################################
# Provider
###############################################################################
provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# IAM User
###############################################################################
resource "aws_iam_user" "tf_admin" {
  name = var.iam_user_name
}

# Create access key for the IAM user
resource "aws_iam_access_key" "tf_admin_key" {
  user = aws_iam_user.tf_admin.name
}

# Format the keys into CSV format
locals {
  tf_admin_keys_csv = "AccessKeyId,SecretAccessKey\n${aws_iam_access_key.tf_admin_key.id},${aws_iam_access_key.tf_admin_key.secret}"
}

# Save the keys to a local CSV file
resource "local_file" "tf_admin_keys" {
  content  = local.tf_admin_keys_csv
  filename = "tf_admin_keys.csv"
}
# resource "aws_iam_user_policy_attachment" "tf_admin_policy" {
#     user       = aws_iam_user.tf_admin.name
#     policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

###############################################################################
# IAM Role for tf_admin to Assume
###############################################################################
resource "aws_iam_role" "tf_admin_role" {
  name = "terraform-admin-role"

  # 신뢰 정책: tf_admin 사용자가 이 역할을 수임(AssumeRole)할 수 있도록 허용합니다.
  # Principal 섹션에 명시된 사용자(tf_admin)만 이 역할을 사용할 수 있습니다.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_user.tf_admin.arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Description = "Role for Terraform admin user to assume"
  }
}

# Attach AdministratorAccess policy to the role
# 실제 운영환경에서는 필요 리소스에만 접근권한 부여
resource "aws_iam_role_policy_attachment" "tf_admin_role_admin_policy" {
  role       = aws_iam_role.tf_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

###############################################################################
# IAM Group
###############################################################################
resource "aws_iam_group" "tf_admin_group" {
  name = "terraform-admin-group"
}

# 그룹에 AssumeRole 권한 부여 (인라인 정책)
resource "aws_iam_group_policy" "tf_admin_group_assume_role_policy" {
  name  = "AllowAssumeTerraformAdminRole"
  group = aws_iam_group.tf_admin_group.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = aws_iam_role.tf_admin_role.arn
      }
    ]
  })
}

resource "aws_iam_group_membership" "tf_admin_membership" {
  name  = "tf-admin-group-membership" # A unique name for the membership resource
  users = [aws_iam_user.tf_admin.name]
  group = aws_iam_group.tf_admin_group.name
}

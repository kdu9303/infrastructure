###############################################################################
# Provider
###############################################################################
provider "aws" {
  region  = var.region
  profile = var.aws_profile

  # tf_admin 사용자가 역할을 수임하도록 설정 추가
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
    session_name = "TerraformProviderAssumeRole"
  }
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
resource "aws_iam_user" "etluser" {
  name = var.iam_user_name
}

# Create access key for the IAM user
resource "aws_iam_access_key" "etluser_key" {
  user = aws_iam_user.etluser.name
}

# Format the keys into CSV format
locals {
  etluser_keys_csv = "AccessKeyId,SecretAccessKey\n${aws_iam_access_key.etluser_key.id},${aws_iam_access_key.etluser_key.secret}"
}

# Save the keys to a local CSV file
resource "local_file" "etluser_keys" {
  content  = local.etluser_keys_csv
  filename = "etluser_keys.csv"
}


###############################################################################
# IAM Group
###############################################################################
resource "aws_iam_group" "etluser_group" {
  name = "etluser-group"
}


resource "aws_iam_group_membership" "etluser_membership" {
  name  = "etluser-group-membership" # A unique name for the membership resource
  users = [aws_iam_user.etluser.name]
  group = aws_iam_group.etluser_group.name
}

resource "aws_iam_group_policy_attachment" "etluser_group_glue_full" {
  group      = aws_iam_group.etluser_group.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "aws_iam_group_policy_attachment" "etluser_group_s3_full" {
  group      = aws_iam_group.etluser_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_group_policy_attachment" "etluser_group_rds_full" {
  group      = aws_iam_group.etluser_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_group_policy_attachment" "etluser_group_dynamodb_full" {
  group      = aws_iam_group.etluser_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

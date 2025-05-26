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

##############################################################################
# IAM User
###############################################################################
resource "aws_iam_user" "visuser" {
  name = var.iam_user_name
}

# Create access key for the IAM user
resource "aws_iam_access_key" "visuser_key" {
  user = aws_iam_user.visuser.name
}

# Format the keys into CSV format
locals {
  visuser_keys_csv = "AccessKeyId,SecretAccessKey\n${aws_iam_access_key.visuser_key.id},${aws_iam_access_key.visuser_key.secret}"
}

# Save the keys to a local CSV file
resource "local_file" "visuser_keys" {
  content  = local.visuser_keys_csv
  filename = "visuser_keys.csv"
}

###############################################################################
# VISUSER: 시각화용 사용자 및 최소 권한 그룹
###############################################################################
resource "aws_iam_group" "visuser_group" {
  name = "visuser-group"
}

resource "aws_iam_group_membership" "visuser_membership" {
  name  = "visuser-group-membership"
  users = [aws_iam_user.visuser.name]
  group = aws_iam_group.visuser_group.name
}

resource "aws_iam_group_policy" "visuser_group_athena_glue_s3" {
  name  = "visuser-athena-glue-s3-policy"
  group = aws_iam_group.visuser_group.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      // Athena 최소 권한
      {
        Effect = "Allow",
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryResults",
          "athena:GetQueryResultsStream",
          "athena:GetWorkGroup",
          "athena:GetQueryExecution",
          "athena:ListWorkGroups",
          "athena:ListQueryExecutions",
          "athena:ListDatabases",
          "athena:ListTableMetadata"
        ],
        Resource = "*"
      },
      // Glue Catalog 읽기 권한
      {
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:GetUserDefinedFunctions",
          "glue:GetTableVersion",
          "glue:GetTableVersions"
        ],
        Resource = "*"
      },
      // S3 버킷 접근 (데이터/쿼리 결과)
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ],
        Resource = "*"
      },
      // (선택) Athena 쿼리 로그 조회
      {
        Effect = "Allow",
        Action = [
          "logs:GetLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      }
    ]
  })
}

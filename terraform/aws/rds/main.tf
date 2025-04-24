provider "aws" {
  region  = local.region
  profile = "dataengineer"
}

# Terraform state 저장용 S3 버킷
resource "aws_s3_bucket" "tfstate" {
  bucket = var.backend_bucket_name
  tags = local.tags
}

# Terraform state 저장용 S3 버킷 버저닝
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = var.backend_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

variable "backend_bucket_name" {
  type    = string
  default = "greta-db-terraform-backend-tfstate"
}

locals {
  name   = "greta-db"
  region = "ap-northeast-2"

  tags = {
    Name       = "greta-db_rds_terraform_state"
    User = "dataengineer"
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-rds"
  }
}
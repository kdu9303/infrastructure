###############################################################################
# Provider
###############################################################################
provider "aws" {
  region  = var.region
  profile = var.etluser_profile
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
# S3 Bucket
###############################################################################
resource "aws_s3_bucket" "real_estate_silver" {
  bucket = "real-estate-silver"

  # (옵션) 버킷 삭제시 객체도 함께 삭제 (개발/테스트 환경에서만 권장)
  force_destroy = true

  # (옵션) 태그 예시
  tags = {
    Environment = "dev"
    Project     = "real-estate"
  }
}

resource "aws_s3_bucket_public_access_block" "real_estate_silver" {
  bucket = aws_s3_bucket.real_estate_silver.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "real_estate_silver" {
  bucket = aws_s3_bucket.real_estate_silver.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


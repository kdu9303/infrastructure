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
# glue database
###############################################################################

resource "aws_glue_catalog_database" "real_estate" {
  name = "real-estate"
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-real-estate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_s3" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_crawler_glue" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}


resource "aws_glue_crawler" "real_estate_raw" {
  name          = "real-estate-raw-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.real_estate.name

  s3_target {
    path = "s3://real-estate-raw/"
  }

  table_prefix = "source_"
}


resource "aws_glue_crawler" "real_estate_silver" {
  name          = "real-estate-silver-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.real_estate.name

  s3_target {
    path = "s3://real-estate-silver/"
  }

}

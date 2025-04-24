terraform {
  backend "s3" { 
    bucket  = "greta-db-terraform-backend-tfstate"
    key     = "rds/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "dataengineer"
    shared_credentials_file = "$HOME/.aws/credentials"
  }
}
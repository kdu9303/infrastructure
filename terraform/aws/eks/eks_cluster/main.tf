terraform {
  #   backend "s3" {
  #     bucket = "XXXXXXXXXXXX-bucket-state-file-karpenter"
  #     region = "ap-northeast-2"
  #     key    = "karpenter.tfstate"
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  required_version = ">= 1.0"
}

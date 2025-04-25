###############################################################################
# Provider
###############################################################################

provider "aws" {
  region = var.region
  # profile = var.aws_profile
  # shared_config_files=["~/.aws/config"] # Or $HOME/.aws/config
  # shared_credentials_files = ["~/.aws/credentials"] # Or $HOME/.aws/credentials
  # allowed_account_ids = ["XXXXXX"]

  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
    session_name = "TerraformProviderAssumeRole"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"

  # tf_admin 사용자가 역할을 수임하도록 설정 추가
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
    session_name = "TerraformProviderAssumeRoleVirginia"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--role-arn",
      "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
    ]
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--role-arn",
      "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--role-arn",
        "arn:aws:iam::${var.aws_account_id}:role/terraform-admin-role"
      ]
    }
  }
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "eks-cluster"
}

variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "aws_profile" {
  description = "AWS 프로필"
  type        = string
  # default     = "tf_admin"
  default = "default"
}

variable "cluster_version" {
  description = "Kubernetes 버전"
  type        = string
  default     = "1.32"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "node_instance_types" {
  description = "EKS 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_group_desired_size" {
  description = "노드 그룹 기본 크기"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "노드 그룹 최소 크기"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "노드 그룹 최대 크기"
  type        = number
  default     = 4
}

variable "node_group_capacity_type" {
  description = "노드 그룹 용량 타입 (ON_DEMAND 또는 SPOT)"
  type        = string
  default     = "SPOT"
}

locals {
  common_tags = {
    environment  = "dev"
    created_user = "tf_admin"
    create_date  = "2025-04-25"
    terraform    = "true"
  }
  dynamic_tags = {
     updated_date = formatdate("YYYY-MM-DD", timestamp())
  }
  all_tags = merge(local.common_tags, local.dynamic_tags)
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default = {
    environment  = "dev"
    created_user = "tf_admin"
    create_date  = "2025-04-25"
    terraform    = "true"
  }
} 
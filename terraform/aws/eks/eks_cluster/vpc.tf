###############################################################################
# VPC
###############################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  # enable_dns_hostnames = true
  # enable_dns_support   = true  # DNS 지원 활성화

  # NAT 게이트웨이 설정 - 신뢰성 향상을 위해 모든 AZ에 설정
  # one_nat_gateway_per_az = true   # 각 AZ마다 하나의 NAT 게이트웨이 

  # VPC 흐름 로그 활성화
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  # Kubernetes에 필요한 서브넷 태그 설정
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  tags = var.tags
}

# ###############################################################################
# # VPC 엔드포인트 (별도 리소스로 추가)
# ###############################################################################

# # S3 Gateway 엔드포인트
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = module.vpc.vpc_id
#   service_name      = "com.amazonaws.${var.region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = module.vpc.private_route_table_ids

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-s3-endpoint"
#     }
#   )
# }

# # ECR API 엔드포인트
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${var.region}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-ecr-api-endpoint"
#     }
#   )
# }

# # ECR DKR 엔드포인트
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${var.region}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-ecr-dkr-endpoint"
#     }
#   )
# }

# # VPC 엔드포인트를 위한 보안 그룹
# resource "aws_security_group" "vpc_endpoints" {
#   name        = "${var.cluster_name}-vpc-endpoints-sg"
#   description = "Security group for VPC endpoints"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#     description = "Allow HTTPS traffic from within VPC"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outbound traffic"
#   }

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-vpc-endpoints-sg"
#     }
#   )
# } 
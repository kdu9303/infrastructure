# ###############################################################################
# # EKS Pod Identity를 위한 IAM 역할 및 정책 설정
# ###############################################################################

# # 1. 파드가 수임(Assume)할 IAM 역할 정의
# data "aws_iam_policy_document" "pod_identity_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"] # EKS Pod Identity 서비스 주체
#     }
#     # 조건(Condition): 신뢰 범위를 특정 클러스터 및 계정으로 제한 (보안 강화)
#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values   = [data.aws_caller_identity.current.account_id]
#     }
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"
#       # EKS 클러스터의 ARN 패턴 지정
#       values   = ["arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"]
#     }
#   }
# }

# resource "aws_iam_role" "my_app_pod_identity_role" {
#   name               = "${var.cluster_name}-my-app-pod-identity-role"
#   # 위에서 정의한 신뢰 정책 문서 사용
#   assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role_policy.json

#   tags = merge(var.tags, {
#     "Description" = "EKS Pod Identity를 위한 IAM 역할 (my-app-sa)"
#   })
# }

# # 2. 역할에 정책 연결
# # S3 접근 권한 추가
# resource "aws_iam_role_policy_attachment" "my_app_pod_identity_s3_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   role       = aws_iam_role.my_app_pod_identity_role.name
# }

# # RDS 접근 권한 추가
# resource "aws_iam_role_policy_attachment" "my_app_pod_identity_rds_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
#   role       = aws_iam_role.my_app_pod_identity_role.name
# }

# # 3. EKS Pod Identity 연결 생성
# # 특정 네임스페이스의 특정 쿠버네티스 서비스 어카운트와 IAM 역할을 연결합니다.
# resource "aws_eks_pod_identity_association" "my_app_sa" {
#   cluster_name = module.eks.cluster_name
#   namespace    = "default"             # 대상 네임스페이스 (애플리케이션에 맞게 수정)
#   service_account = "my-app-sa"        # 대상 서비스 어카운트 이름 (애플리케이션에 맞게 수정)
#   role_arn     = aws_iam_role.my_app_pod_identity_role.arn

#   tags = merge(var.tags, {
#     "Description" = "EKS Pod Identity 연결 (my-app-sa)"
#   })
# }

# # 현재 AWS 계정 ID를 가져오기 위한 필수 데이터 소스
# data "aws_caller_identity" "current" {} 
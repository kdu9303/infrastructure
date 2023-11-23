# terraform 헬름 모듈에 필요한 환경변수 설정
#  ->  export KUBE_CONFIG_PATH=/Users/isc/.kube/config

# module "load_balancer_controller" {
#   source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"

#   cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
#   cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
#   cluster_name                     = "greta-eks"

#   depends_on = [module.eks]
# }


# module "alb-ingress-controller" {
#   source  = "campaand/alb-ingress-controller/aws"
#   version = "2.0.0"

#   cluster_name = local.name
# }


module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  
  create_instance_profile = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  }

  tags = merge(tomap({
    "eks_addon" = "karpenter"
    }),
    local.tags,
  )
}

# Checking EC2 API connectivity, WebIdentityErr: failed to retrieve credentials caused by: 
# AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity status code: 403
# resource "helm_release" "karpenter_crd" {
#   # depends_on = [module.eks]
#   namespace        = "karpenter"
#   create_namespace = true

#   name         = "karpenter-crd"
#   repository   = "oci://public.ecr.aws/karpenter"
#   chart        = "karpenter-crd"
#   version      = "v0.33.0"
#   replace      = true
#   force_update = true

# }

# resource "helm_release" "karpenter" {
#   depends_on       = [module.eks, helm_release.karpenter_crd]
#   namespace        = "karpenter"
#   create_namespace = true

#   name       = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter"
#   version    = "v0.33.0"
#   replace    = true

#   set {
#     name  = "serviceMonitor.enabled"
#     value = "True"
#   }

#   set {
#     name = "settings.clusterName"
#     value = module.eks.cluster_name
#     # value = module.eks.cluster_id
#   }

#   set {
#     name  = "settings.clusterEndpoint"
#     value = module.eks.cluster_endpoint
#   }

#   set {
#     name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     # value = module.karpenter.iam_role_arn
#     # value = aws_iam_role.karpenter_controller.arn
#     value = "arn:aws:iam::633647824487:role/KarpenterControllerRole-${local.name}"
#   }

#   set {
#     name  = "settings.aws.interruptionQueueName"
#     value = module.karpenter.queue_name
#   }

#   set {
#     name  = "tolerations[0].key"
#     value = "system"
#   }

#   set {
#     name  = "tolerations[0].value"
#     value = "owned"
#   }

#   set {
#     name  = "tolerations[0].operator"
#     value = "Equal"
#   }

#   set {
#     name  = "tolerations[0].effect"
#     value = "NoSchedule"
#   }

#   set {
#     name  = "aws.defaultInstanceProfile"
#     # value = aws_iam_instance_profile.karpenter.name
#     value = "KarpenterNodeInstanceProfile-${local.name}"
#   }

# }

# resource "kubectl_manifest" "karpenter_node_class" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1beta1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiFamily: AL2
#       role: ${module.karpenter.node_iam_role_name}
#       subnetSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks.cluster_name}
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks.cluster_name}
#       tags:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }


# # # Node pool 설정
# resource "kubectl_manifest" "karpenter_spot_pool" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1beta1
#     kind: NodePool
#     metadata:
#       name: spot
#     spec:
#       disruption:
#         consolidationPolicy: WhenUnderutilized
#         expireAfter: 72h
#       limits:
#         cpu: 100
#         memory: 8Gi
#       template:
#         spec:
#           nodeClassRef:
#             name: default
#           requirements:
#             - key: "karpenter.k8s.aws/instance-category"
#               operator: In
#               values: ["t"]
#             - key: karpenter.sh/capacity-type
#               operator: In
#               values: ["spot"]
#             - key: kubernetes.io/arch
#               operator: In
#               values: ["amd64"]
#             - key: karpenter.k8s.aws/instance-size
#               operator: In
#               values: [medium, large]
#           taints:
#           - key: spot
#             value: "true"
#             effect: NoSchedule

# YAML
#   depends_on = [
#     helm_release.karpenter
#   ]
# }
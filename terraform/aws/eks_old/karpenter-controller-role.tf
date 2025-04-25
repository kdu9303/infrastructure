resource "aws_iam_role" "nodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = aws_iam_role.nodes.name
}


# data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test = "StringEquals"
#       variable = "${module.eks.oidc_provider}:sub"
#       values   = ["system:serviceaccount:karpenter:karpenter"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${module.eks.oidc_provider}:aud"
#       values   = ["sts.amazonaws.com"]
#     }

#     principals {
#       identifiers = [module.eks.oidc_provider]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "karpenter_controller" {
#   assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
#   name               = "karpenter-controller"
# }

# resource "aws_iam_policy" "karpenter_controller" {
#   policy = file("./controller-trust-policy.json")
#   name   = "KarpenterController"
# }

# resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
#   role       = aws_iam_role.karpenter_controller.name
#   policy_arn = aws_iam_policy.karpenter_controller.arn
# }

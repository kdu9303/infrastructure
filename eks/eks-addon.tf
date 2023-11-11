# variable "aws_account_id" {
#   type = string
#   # default = ""
#   description = "set TF_VAR_aws_account_id=< account id >"

# }

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  # service_account_role_arn    = "arn:aws:iam::${var.aws_account_id}:role/ebs-csi-switch-eks"
  service_account_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ebs-csi-switch-eks"
  addon_version               = "v1.23.1-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}
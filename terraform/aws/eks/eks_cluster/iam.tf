# IAM Policy to allow describing the specific EKS cluster
resource "aws_iam_policy" "allow_eks_describe_cluster" {
  name        = "${var.cluster_name}-allow-describe-cluster"
  description = "Allows describing the ${var.cluster_name} EKS cluster specifically"

  # Policy document allowing eks:DescribeCluster on the created cluster resource
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        # Construct the specific cluster ARN using variables
        Resource = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.cluster_name}"
      },
    ]
  })

  tags = var.tags
}


# # Attach the policy to the tf_admin user
# resource "aws_iam_user_policy_attachment" "tf_admin_eks_describe_attachment" {
#   # Ensure you have the correct IAM user name. If it's different, update this value.
#   user       = "tf_admin" 

# Attach the policy to the terraform-admin-group
resource "aws_iam_group_policy_attachment" "tf_admin_group_eks_describe_attachment" {
  # Attach the policy to the group defined in the tf_admin module/directory
  group      = "terraform-admin-group"
  policy_arn = aws_iam_policy.allow_eks_describe_cluster.arn
} 
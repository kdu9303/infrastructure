variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}
variable "aws_profile" {
  type    = string
  default = "default"
}

variable "iam_user_name" {
  type    = string
  default = "etluser"
}
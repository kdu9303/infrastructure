variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}
variable "etluser_profile" {
  type    = string
  default = "etluser"
}
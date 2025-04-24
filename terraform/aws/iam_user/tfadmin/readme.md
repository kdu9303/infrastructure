### user aws configure 등록
aws configure
key 등록

[profile tf-admin]
role_arm = arn:aws:iam:....
source_profile = tf_admin

### user identity 확인
aws sts get-caller-identity --profile tf_admin

### user sts assume-role 확인
aws sts assume-role --role-arn arn:aws:iam::XXXXXXXXXX:role/terraform-admin --role-session-name terraform --profile tf_admin

# EKS cluster 환경 설정

AWS EKS 구축을 위한 Terraform code입니다.

## 설치 방법
```shell
    # 1. tfenv 설치
    brew install tfenv
    choco install tfenv

    # terraform 특정 버전 설치
    tfenv install 1.6.0
    tflist

    # terraform 버전 선택
    tfenv use 1.6.0

    # 설치 확인
    terraform --version

    # 프로젝트 초기화(module 호출 등..)
    terraform init
```

## 실행 전 환경 변수 설정 예제 및 실행
```shell
    export TF_VAR_aws_account_id="12341234"
    terraform plan 
    terraform apply --auto-approve
```
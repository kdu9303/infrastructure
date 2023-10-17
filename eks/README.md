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
```
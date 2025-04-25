# Terraform EKS 배포 가이드

이 문서는 Terraform을 사용하여 AWS EKS 클러스터를 배포하는 과정을 안내합니다.

## AWS 자격 증명 및 역할 수임 (kubectl 사용 간소화)

EKS 클러스터와 상호작용하려면 `terraform-admin-role`의 권한이 필요합니다. `kubectl` 사용 시 매번 임시 자격 증명을 수동으로 설정하는 대신, 아래 방법을 사용하면 `kubectl`이 자동으로 역할을 수임하도록 설정할 수 있습니다.

**단계별 절차:**

1.  **기본 AWS 자격 증명 설정 확인:**
    `kubectl`을 사용할 환경(터미널)에 `tf_admin` 사용자의 **영구** 자격 증명(Access Key/Secret Key)이 기본 AWS 자격 증명으로 설정되어 있는지 확인합니다. (예: `~/.aws/credentials`의 `[default]` 프로필). 이 영구 자격 증명에는 `terraform-admin-role`을 수임할 수 있는 `sts:AssumeRole` 권한이 반드시 포함되어 있어야 합니다.

2.  **`kubeconfig` 업데이트 (역할 자동 수임 설정):**
    아래 명령어를 실행하여 로컬 `kubeconfig` 파일을 업데이트합니다. `--role-arn` 옵션을 추가하는 것이 핵심입니다.
    ```bash
    aws eks update-kubeconfig --region <리전 코드> --name <클러스터 이름> --role-arn arn:aws:iam::<aws_account_id>:role/terraform-admin-role
    ```
    *   `<리전 코드>`: 클러스터가 생성된 AWS 리전 (예: `ap-northeast-2`). Terraform 변수 `var.region` 값.
    *   `<클러스터 이름>`: 생성된 EKS 클러스터 이름 (예: `eks-cluster`). Terraform 변수 `var.cluster_name` 값.
    *   `--role-arn`: `kubectl` 실행 시 자동으로 수임할 IAM 역할의 ARN을 지정합니다.

3.  **`kubectl` 사용:**
    이제 별도의 임시 자격 증명 설정 없이 `kubectl` 명령어를 바로 사용할 수 있습니다. `kubectl`이 실행될 때마다 백그라운드에서 자동으로 `terraform-admin-role` 역할을 수임하여 인증을 수행합니다.
    * kubectl get nodes를 실행해야 자동 재인증 진행
    ```bash
    kubectl get nodes
    kubectl cluster-info
    ```

**주의:**

*   이 방법을 사용하면 `kubectl` 사용은 간편해지지만, **Terraform 실행**이나 `--role-arn` 옵션을 지원하지 않는 **다른 AWS CLI 명령어**를 사용할 때는 여전히 수동으로 역할을 수임하고 임시 자격 증명을 설정해야 할 수 있습니다 (아래 '수동 역할 수임' 섹션 참조).
*   기본 AWS 자격 증명(`tf_admin`의 영구 키)은 안전하게 관리되어야 합니다.

## 수동 역할 수임 (일반 AWS CLI 명령어 사용)

`kubectl` 외에 다른 AWS CLI 명령어(예: `aws ecr-public`, `aws s3` 등)를 `terraform-admin-role`의 권한으로 실행해야 하는 경우가 있습니다. 이 역할은 EKS 클러스터 관리 외에도 필요한 다른 AWS 리소스에 대한 접근 권한을 가질 수 있습니다.

이 경우, `aws sts assume-role` 명령어를 사용하여 수동으로 역할을 수임하고 임시 자격 증명을 얻어야 합니다.

**단계별 절차:**

1.  **역할 수임 및 임시 자격 증명 발급:**
    `tf_admin` 사용자의 영구 자격 증명이 설정된 환경에서 아래 명령어를 실행합니다.
    ```bash
    aws sts assume-role --role-arn arn:aws:iam::<aws_account_id>:role/terraform-admin-role --role-session-name ECRPublicAccessSession
    ```
    *   `<aws_account_id>`: 실제 AWS 계정 ID로 변경해야 합니다.
    *   `--role-session-name`: 세션을 구분하기 위한 임의의 이름입니다.


2.  **임시 자격 증명 환경 변수 설정:**
    위 명령어의 출력 결과에서 `Credentials` 섹션 아래의 `AccessKeyId`, `SecretAccessKey`, `SessionToken` 값을 복사하여 현재 터미널 세션의 환경 변수로 설정합니다.
    
    **Bash/Zsh (Linux/macOS):**
    ```bash
    export AWS_ACCESS_KEY_ID="<AccessKeyId 값>"
    export AWS_SECRET_ACCESS_KEY="<SecretAccessKey 값>"
    export AWS_SESSION_TOKEN="<SessionToken 값>"
    ```
    
    **PowerShell (Windows):**
    ```powershell
    $env:AWS_ACCESS_KEY_ID=""
    $env:AWS_SECRET_ACCESS_KEY=""
    $env:AWS_SESSION_TOKEN=""
    ```
    
    **CMD (Windows):**
    ```cmd
    set AWS_ACCESS_KEY_ID=<AccessKeyId 값>
    set AWS_SECRET_ACCESS_KEY=<SecretAccessKey 값>
    set AWS_SESSION_TOKEN=<SessionToken 값>
    ```

3.  **필요한 AWS CLI 명령어 실행:**
    이제 임시 자격 증명이 적용된 상태이므로, `terraform-admin-role`이 허용하는 필요한 명령어를 실행할 수 있습니다.
    ```bash
    aws ecr-public get-login-password --region us-east-1
    # 기타 필요한 AWS CLI 명령어 실행
    ```

4.  **(선택 사항) 환경 변수 해제:**
    임시 자격 증명 사용이 완료되면, 보안을 위해 설정했던 환경 변수를 해제하는 것이 좋습니다.
    ```bash
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    ```

**주의:**

*   임시 자격 증명은 유효 기간이 있으며, 만료되면 1단계부터 다시 수행해야 합니다.
*   `tf_admin` 사용자에게 `sts:AssumeRole` 권한이 `terraform-admin-role`에 대해 허용되어 있어야 합니다.

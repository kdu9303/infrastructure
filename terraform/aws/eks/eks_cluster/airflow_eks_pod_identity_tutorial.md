# 튜토리얼: EKS Pod Identity를 사용하여 Airflow에서 AWS 리소스 접근하기

이 튜토리얼에서는 AWS EKS(Elastic Kubernetes Service) 환경에서 Apache Airflow를 Helm 차트로 배포하고, EKS Pod Identity를 활용하여 Airflow 파드가 안전하게 AWS 리소스(예: S3 버킷, RDS 데이터베이스)에 접근하도록 구성하는 방법을 설명합니다.

## 목표

*   Airflow 파드 내부에 AWS 자격 증명(Access Key, Secret Key)을 직접 저장하지 않고 AWS 서비스에 접근합니다.
*   Terraform을 사용하여 필요한 AWS IAM 역할과 EKS Pod Identity 연결을 자동화합니다.
*   Airflow Helm 차트 설정을 수정하여 Pod Identity를 사용하도록 구성합니다.

## 사전 요구 사항

*   AWS 계정 및 AWS CLI 설정 완료
*   Terraform 설치 완료
*   kubectl 설치 및 EKS 클러스터 접근 권한 설정 완료
*   Helm 설치 완료
*   기존 EKS 클러스터 (`module.eks.cluster_name` 등으로 Terraform에서 참조 가능해야 함)

## 단계 1: Terraform으로 IAM 역할 및 Pod Identity 연결 생성

먼저 Terraform을 사용하여 Airflow 파드가 사용할 IAM 역할과 이를 특정 Kubernetes 서비스 어카운트에 연결하는 Pod Identity Association을 정의합니다.

아래 코드는 `terraform/aws/eks/eks_cluster/pod_identity.tf` 파일의 예시입니다.

```terraform
###############################################################################
# EKS Pod Identity를 위한 IAM 역할 및 정책 설정
###############################################################################

# 현재 AWS 계정 ID 가져오기 (다른 곳에서 정의되어 있다면 생략 가능)
data "aws_caller_identity" "current" {}

# 1. 파드가 수임(Assume)할 IAM 역할 정의
data "aws_iam_policy_document" "airflow_pod_identity_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      # EKS Pod Identity 서비스 주체
      identifiers = ["pods.eks.amazonaws.com"]
    }
    # 조건: 특정 EKS 클러스터 및 계정으로 신뢰 범위 제한 (보안 강화)
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      # 실제 EKS 클러스터 ARN 패턴으로 수정해야 합니다.
      # module.eks.cluster_name 등 클러스터 이름을 참조하는 변수를 사용하세요.
      values   = ["arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"]
    }
  }
}

# Airflow 파드가 사용할 IAM 역할 생성
resource "aws_iam_role" "airflow_pod_identity_role" {
  # 역할 이름은 환경에 맞게 조정하세요.
  name               = "${var.cluster_name}-airflow-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.airflow_pod_identity_assume_role_policy.json

  tags = merge(var.tags, {
    "Description" = "EKS Pod Identity 역할 (Airflow)"
  })
}

# 2. 역할에 필요한 정책 연결 (예: S3 및 RDS 접근)
# 중요: 실제 운영 환경에서는 필요한 최소한의 권한만 부여하세요.
resource "aws_iam_role_policy_attachment" "airflow_pod_identity_s3_policy" {
  # 예시: S3 전체 접근 권한 (최소 권한 원칙에 따라 수정 필요)
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.airflow_pod_identity_role.name
}

resource "aws_iam_role_policy_attachment" "airflow_pod_identity_rds_policy" {
  # 예시: RDS 전체 접근 권한 (최소 권한 원칙에 따라 수정 필요)
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.airflow_pod_identity_role.name
}

# 3. EKS Pod Identity 연결 생성
# 이 연결은 특정 네임스페이스의 특정 서비스 어카운트와 위에서 만든 IAM 역할을 연결합니다.
resource "aws_eks_pod_identity_association" "airflow_sa_association" {
  cluster_name = module.eks.cluster_name # 실제 클러스터 이름 참조
  # Airflow를 배포할 네임스페이스와 일치해야 합니다.
  namespace    = "airflow"
  # Airflow Helm 차트에서 사용할 서비스 어카운트 이름과 일치해야 합니다.
  service_account = "airflow-sa"
  role_arn     = aws_iam_role.airflow_pod_identity_role.arn

  tags = merge(var.tags, {
    "Description" = "EKS Pod Identity 연결 (Airflow)"
  })
}
```

**주의:**

*   `aws_eks_pod_identity_association`의 `namespace`와 `service_account` 값 (`airflow`, `airflow-sa`)은 **다음 단계에서 Airflow Helm 차트를 설정할 때 사용할 값과 정확히 일치해야 합니다.**
*   IAM 정책은 예시이며, 실제 운영 환경에서는 필요한 최소 권한으로 제한하는 것이 보안상 매우 중요합니다. (`AmazonS3FullAccess`, `AmazonRDSFullAccess`는 과도한 권한일 수 있습니다.)

위 Terraform 코드를 작성하거나 수정한 후 `terraform init` 및 `terraform apply`를 실행하여 AWS 리소스를 생성합니다.

## 단계 2: Airflow Helm Chart 설정 수정

Airflow Helm 차트를 배포할 때, Airflow 구성 요소(Webserver, Scheduler, Workers 등)가 사용할 서비스 어카운트 이름을 Terraform에서 지정한 이름(`airflow-sa`)으로 설정해야 합니다.

Airflow Helm 차트의 `values.yaml` 파일을 수정하거나 `helm install/upgrade` 명령어에 `--set` 플래그를 사용합니다.

**`values.yaml` 파일 수정 예시:**

```yaml
# values.yaml

# Airflow를 배포할 네임스페이스 (Terraform의 namespace와 일치)
# 이 값은 values.yaml에 직접 설정하는 것이 아니라, helm install/upgrade 시 -n 플래그로 지정하는 것이 일반적입니다.
# 예: helm install airflow apache-airflow/airflow -n airflow -f values.yaml

# Airflow 컴포넌트들이 사용할 서비스 어카운트 이름 지정
serviceAccount:
  # 새 서비스 어카운트를 생성할지 여부.
  # Pod Identity를 사용하므로 Kubernetes 서비스 어카운트 자체는 필요합니다.
  create: true
  # 사용할 서비스 어카운트 이름 (Terraform의 service_account와 일치)
  name: airflow-sa

# 필요에 따라 각 컴포넌트별로 다른 서비스 어카운트를 지정할 수도 있지만,
# 위 serviceAccount.name만 설정하면 모든 Airflow 컴포넌트가 해당 SA를 사용합니다.

# ... 기타 Airflow 설정 ...

# 예시: Airflow 메타데이터 DB로 외부 RDS 사용 설정
# (참고: https://airflow.apache.org/docs/helm-chart/stable/production-guide.html#database)
postgresql:
  enabled: false # 내장 PostgreSQL 비활성화

data:
  metadataConnection:
    # Pod Identity는 AWS API 접근 권한을 제공합니다.
    # DB 연결 자체는 사용자 이름/비밀번호 또는 RDS IAM 인증을 사용할 수 있습니다.
    user: "<rds_username>"
    pass: "<rds_password>" # Kubernetes Secret 사용 권장 (metadataSecretName)
    protocol: postgresql
    host: "<your_rds_endpoint>"
    port: 5432
    db: "<your_airflow_db_name>"
  # 또는 Kubernetes Secret 사용
  # metadataSecretName: airflow-metadata-secret

# ... 기타 Airflow 설정 ...
```

**Helm 명령어로 설정 예시:**

```bash
helm install airflow apache-airflow/airflow \
  --namespace airflow \ # Terraform에서 지정한 네임스페이스
  --create-namespace \
  --set serviceAccount.create=true \
  --set serviceAccount.name=airflow-sa \ # Terraform에서 지정한 서비스 어카운트
  -f values.yaml # 기타 설정이 담긴 파일
```

**설정 확인:**

Helm 차트 배포 후, Airflow 파드들이 올바른 서비스 어카운트(`airflow-sa`)를 사용하는지 확인합니다.

```bash
kubectl get pods -n airflow -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}'
```

출력에서 파드 이름 옆에 `airflow-sa`가 표시되어야 합니다.

## 단계 3: Airflow에서 AWS 서비스 사용

이제 Airflow DAG 내에서 AWS 서비스(S3, RDS 등)와 상호 작용하는 코드를 작성할 때, 별도의 AWS 자격 증명을 제공할 필요가 없습니다. `boto3`와 같은 AWS SDK는 자동으로 EKS Pod Identity를 통해 주입된 IAM 역할 자격 증명을 사용합니다.

**예시: Airflow Connection 설정**

Airflow UI에서 AWS 관련 Connection을 설정할 때 (예: `aws_default`, S3, Redshift 등), **AWS Access Key ID** 및 **Secret Access Key** 필드를 비워두십시오. "Role ARN"이나 다른 인증 관련 필드도 Pod Identity를 사용하는 경우에는 보통 비워둡니다. SDK가 환경에서 자격 증명을 자동으로 찾습니다.

**예시: DAG에서 Boto3 사용**

```python
import boto3
from airflow.decorators import task
from airflow.models.dag import DAG
import pendulum

# 자격 증명을 명시적으로 전달할 필요 없음
s3_client = boto3.client('s3')

@task
def list_s3_buckets():
    response = s3_client.list_buckets()
    print("S3 Buckets:")
    for bucket in response['Buckets']:
        print(f'  {bucket["Name"]}')

with DAG(
    dag_id='eks_pod_identity_s3_test',
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"),
    catchup=False,
    schedule=None,
    tags=['aws', 'pod-identity'],
) as dag:
    list_s3_buckets()
```

이 DAG를 실행하면 Airflow 워커 파드는 Pod Identity를 통해 얻은 권한으로 S3 버킷 목록을 성공적으로 가져올 수 있습니다.

## 보안 고려 사항

*   **최소 권한 원칙**: Terraform에서 IAM 역할에 정책을 연결할 때, Airflow 작업에 필요한 최소한의 권한만 부여하십시오. `AmazonS3FullAccess`나 `AmazonRDSFullAccess`와 같은 광범위한 정책은 실제 운영 환경에서는 사용하지 않는 것이 좋습니다. 필요한 특정 작업(예: `s3:GetObject`, `s3:PutObject`)과 특정 리소스(특정 버킷 ARN)로 권한을 제한하세요.
*   **네임스페이스 및 서비스 어카운트 분리**: 가능하면 Airflow 전용 네임스페이스를 사용하고, 다른 애플리케이션과 서비스 어카운트를 공유하지 마십시오.

이제 EKS Pod Identity를 사용하여 Airflow 파드가 안전하고 효율적으로 AWS 리소스에 접근할 수 있게 되었습니다! 
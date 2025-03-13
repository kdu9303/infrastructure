# Kind 클러스터 설정 가이드

## 사전 요구사항
- Docker 설치
- Kind 설치: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
- kubectl 설치: https://kubernetes.io/ko/docs/tasks/tools/install-kubectl/

## 클러스터 배포 방법
- kind create cluster --config=k8s/kind/cluster.yaml
  - 이 명령은 `cluster.yaml` 파일에 정의된 설정으로 Kind 클러스터를 생성합니다.
  - 클러스터 이름은 `local-k8s`로 설정됩니다.
  - 1개의 컨트롤 플레인 노드와 2개의 워커 노드가 생성됩니다.
  - 포트 매핑: 80, 443 포트가 호스트와 컨테이너 간에 매핑됩니다.

## 클러스터 상태 확인
```bash
# 클러스터 노드 확인
kubectl get nodes

# 클러스터 정보 확인
kubectl cluster-info
```

## kubectl 설정 방법
Kind 클러스터를 생성하면 자동으로 kubectl 설정이 업데이트됩니다. 수동으로 설정하려면:

```bash
# 현재 컨텍스트 확인
kubectl config current-context

# 컨텍스트 목록 확인
kubectl config get-contexts

# kind 클러스터로 컨텍스트 전환
kubectl config use-context kind-local-k8s
```

## 클러스터 삭제 방법
```bash
# 클러스터 삭제
kind delete cluster --name local-k8s
```

## 클러스터 구성 설명
현재 클러스터 구성(`cluster.yaml`)은 다음과 같습니다:
- 1개의 컨트롤 플레인 노드
- 2개의 워커 노드
- 파드 서브넷: 10.244.0.0/16
- 서비스 서브넷: 10.96.0.0/12
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

## Kubeconfig 파일 추출 및 공유
다른 PC에서 클러스터에 접근하려면 kubeconfig 파일을 추출하여 공유할 수 있습니다:

```bash
# kubeconfig 파일 추출
kind get kubeconfig --name local-k8s > kubeconfig.yaml
```

이 명령어는 Kind 클러스터의 kubeconfig 정보를 추출하여 `kubeconfig.yaml` 파일로 저장합니다. 이 파일에는 클러스터 접속에 필요한 인증 정보와 API 서버 주소가 포함되어 있습니다.

### 다른 PC에서 사용하기 위한 kubeconfig 수정
다른 PC에서 사용하려면 kubeconfig 파일의 서버 주소를 호스트 머신의 실제 IP 주소로 수정해야 합니다:

1. kubeconfig.yaml 파일을 텍스트 편집기로 열기
2. `server: https://127.0.0.1:6443` 부분을 `server: https://호스트IP:6443`으로 변경
   (예: `server: https://192.168.0.7:6443`)
3. 수정된 파일을 다른 PC로 복사

다른 PC에서는 다음과 같이 사용할 수 있습니다:
```bash
export KUBECONFIG=/path/to/kubeconfig.yaml
kubectl get nodes
```

또는 명령어마다 kubeconfig 파일을 지정할 수도 있습니다:
```bash
kubectl --kubeconfig=/path/to/kubeconfig.yaml get nodes
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
- API 서버 주소: 192.168.0.7 (내부 IP 사용)
- API 서버 포트: 6443
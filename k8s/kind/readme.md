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

## 로컬 레지스트리 연동하기

### 로컬 레지스트리 실행

먼저 로컬 레지스트리와 UI를 실행합니다:

```bash
cd /c:/Developer/infrastructure/docker_files/local-registry
docker-compose up -d
```

이렇게 하면 다음 서비스가 실행됩니다:
- 레지스트리 API: http://localhost:5000
- 레지스트리 UI: http://localhost:18580

### Kind와 레지스트리 연결

제공된 스크립트를 사용하여 Kind 클러스터를 생성하고 로컬 레지스트리와 연결합니다:

```bash
cd /c:/Developer/infrastructure/k8s/kind
chmod +x setup-registry.sh
./setup-registry.sh
```

### 윈도우에서 실행하기

윈도우에서는 제공된 BAT 또는 PowerShell 스크립트를 사용할 수 있습니다:

#### PowerShell 스크립트 실행
관리자 권한으로 PowerShell을 실행하고 다음 명령어를 입력합니다:
```powershell
# 처음 실행 시 실행 정책 설정 필요
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 스크립트 실행
cd C:\Developer\infrastructure\k8s\kind
.\setup-registry.ps1
```

#### BAT 파일 실행
명령 프롬프트나 파일 탐색기에서 직접 실행합니다:
```cmd
C:\Developer\infrastructure\k8s\kind\setup-local-registry.bat
```

BAT 파일은 다음 순서로 작업을 수행합니다:
1. 도커 실행 여부 확인
2. 로컬 레지스트리 시작 (필요한 경우)
3. kind 네트워크 생성 (필요한 경우)
4. kind 클러스터 생성 (필요한 경우)
5. 레지스트리와 클러스터 연결 설정

### 로컬 레지스트리 사용 방법

#### 이미지 태그 지정 및 푸시

```bash
# 이미지 준비 (예: nginx 이미지 다운로드)
docker pull nginx:latest

# 로컬 레지스트리 주소를 사용하여 태그 지정
docker tag nginx:latest localhost:5000/nginx:latest

# 로컬 레지스트리에 이미지 푸시
docker push localhost:5000/nginx:latest
```

#### Pod에서 로컬 레지스트리 이미지 사용

Pod에서 로컬 레지스트리 이미지를 사용할 때는 세 가지 방법이 있습니다:

1. **레지스트리 IP 주소 사용 (권장)**: 레지스트리 컨테이너의 IP 주소를 사용합니다.
   ```bash
   # 레지스트리 IP 확인
   REGISTRY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks.kind}}{{.IPAddress}}{{end}}' registry)
   echo $REGISTRY_IP
   ```

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nginx-pod
   spec:
     containers:
     - name: nginx
       image: 172.18.0.2:5000/nginx:latest  # 실제 IP로 교체
       ports:
       - containerPort: 80
   ```

2. **컨테이너 이름 사용**: 레지스트리 컨테이너 이름을 사용합니다.
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nginx-pod
   spec:
     containers:
     - name: nginx
       image: registry:5000/nginx:latest
       ports:
       - containerPort: 80
   ```

3. **localhost 사용**: 일부 설정에서는 작동할 수 있지만 권장하지 않습니다.
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nginx-pod
   spec:
     containers:
     - name: nginx
       image: localhost:5000/nginx:latest
       ports:
       - containerPort: 80
   ```

#### 레지스트리 이미지 확인 방법

API를 통해 확인:
```bash
curl http://localhost:5000/v2/_catalog
```

또는 웹 UI를 통해 확인:
http://localhost:18580

### 이미지 풀 오류 해결 방법

레지스트리 이미지 풀 오류가 발생하는 경우, 다음과 같은 방법으로 해결할 수 있습니다:

1. **레지스트리 IP 주소 사용하기**: Pod 생성 시 `localhost:5000` 대신 레지스트리의 IP 주소를 사용합니다.
   ```bash
   # 레지스트리 IP 확인
   REGISTRY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks.kind}}{{.IPAddress}}{{end}}' registry)
   ```

2. **hosts.toml 파일 검증**: 노드에 레지스트리 설정이 올바르게 적용되었는지 확인합니다.
   ```bash
   # control-plane 노드에서 확인
   docker exec local-k8s-control-plane ls -la /etc/containerd/certs.d/
   docker exec local-k8s-control-plane cat /etc/containerd/certs.d/localhost:5000/hosts.toml
   ```

3. **레지스트리 연결 테스트**: 클러스터 내부에서 레지스트리에 접근할 수 있는지 테스트합니다.
   ```bash
   kubectl run -it --rm --image=curlimages/curl:latest curl-test -- curl -v http://registry:5000/v2/_catalog
   ```

4. **레지스트리 재시작 및 네트워크 재연결**:
   ```bash
   # 레지스트리 재시작
   docker-compose -f /c:/Developer/infrastructure/docker_files/local-registry/docker-compose.yml restart

   # 네트워크 연결 다시 확인
   docker network disconnect kind registry
   docker network connect kind registry
   ```

5. **전체 설정 테스트**: 테스트 스크립트로 전체 설정을 확인합니다.
   ```bash
   cd /c:/Developer/infrastructure/k8s/kind
   ./test-registry.ps1
   ```

### 문제 해결 방법

1. 이미지 풀 에러 발생 시:
   ```bash
   # 레지스트리가 kind 네트워크에 연결되었는지 확인
   docker network inspect kind
   
   # 노드에 레지스트리 설정이 올바르게 구성되었는지 확인
   docker exec -it local-k8s-control-plane ls -la /etc/containerd/certs.d/localhost:5000/
   ```

2. 컨테이너 실행 상태 확인:
   ```bash
   docker ps | grep registry
   ```

3. 윈도우에서 발생하는 특정 문제:
   - 경로 문제: Windows에서는 경로 구분자가 `\`이므로 스크립트에서 경로를 지정할 때 주의해야 합니다.
   - PowerShell 실행 정책: PowerShell 스크립트를 처음 실행할 때 실행 정책을 설정해야 할 수 있습니다.
   - 관리자 권한: 일부 작업은 관리자 권한이 필요할 수 있습니다.

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
- 로컬 레지스트리 연결 구성 추가
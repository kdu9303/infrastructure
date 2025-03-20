# 로컬 Docker 레지스트리 및 UI

이 프로젝트는 로컬 Docker 레지스트리와 웹 기반 UI를 제공하여 Docker 이미지를 로컬에서 관리할 수 있게 해줍니다.

## 구성 요소

1. **Docker Registry (registry:latest)** - Docker 이미지를 저장하고 관리하는 레지스트리 서버
2. **Registry UI (joxit/docker-registry-ui)** - 레지스트리의 이미지를 시각적으로 관리할 수 있는 웹 인터페이스

## 설치 및 실행 방법

### 사전 요구 사항

- Docker 및 Docker Compose가 설치되어 있어야 합니다.

### 실행 방법

1. 이 디렉토리로 이동합니다:
   ```bash
   cd docker_files/local-registry
   ```

2. Docker Compose를 사용하여 서비스를 시작합니다:
   ```bash
   docker-compose up -d
   ```

3. 서비스가 실행되면 다음 URL로 접근할 수 있습니다:
   - 레지스트리 API: http://localhost:5000
   - 레지스트리 UI: http://localhost:18580

### 서비스 중지

서비스를 중지하려면 다음 명령을 실행합니다:
```bash
docker-compose down
```

## 레지스트리 사용 방법

### 이미지 푸시하기

1. 이미지에 태그 지정:
   ```bash
   docker tag 이미지명:태그 localhost:5000/이미지명:태그
   ```

2. 이미지 푸시:
   ```bash
   docker push localhost:5000/이미지명:태그
   ```

### 이미지 풀하기

```bash
docker pull localhost:5000/이미지명:태그
```

### 레지스트리 이미지 목록 확인

API를 통해 확인:
```bash
curl http://localhost:5000/v2/_catalog
```

또는 웹 브라우저에서 UI를 통해 확인: http://localhost:18580

## Kind 클러스터와 연동하기

### 설정 방법

로컬 레지스트리를 Kind 클러스터와 연동하려면 다음 단계를 따릅니다:

1. kind 네트워크 생성 (아직 없는 경우):
   ```bash
   docker network create kind
   ```

2. docker-compose.yml 파일에서 kind 네트워크를 사용하도록 설정되어 있는지 확인합니다.
   ```yaml
   networks:
     registry-network:
       name: registry-network
       driver: bridge
     kind:
       external: true
       name: kind
   ```

3. 레지스트리를 kind 네트워크에 연결합니다:
   ```bash
   docker network connect kind registry
   ```

4. Kind 클러스터를 생성합니다:
   ```bash
   cd /c:/Developer/infrastructure/k8s/kind
   ./setup-registry.sh     # Linux/Mac 환경
   ```
   
   Windows 환경에서는:
   ```cmd
   cd C:\Developer\infrastructure\k8s\kind
   .\setup-local-registry.bat
   ```
   또는 PowerShell에서:
   ```powershell
   cd C:\Developer\infrastructure\k8s\kind
   .\setup-registry.ps1
   ```

### Kind 클러스터에서 레지스트리 이미지 사용하기

일단 레지스트리가 Kind 클러스터와 연결되면 다음과 같이 이미지를 사용할 수 있습니다:

1. 이미지 준비:
   ```bash
   # 예시: nginx 이미지 다운로드
   docker pull nginx:latest
   
   # 로컬 레지스트리 태그 지정
   docker tag nginx:latest localhost:5000/nginx:latest
   
   # 레지스트리에 푸시
   docker push localhost:5000/nginx:latest
   ```

2. Kubernetes 매니페스트에서 이미지 사용:
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

3. 매니페스트 적용:
   ```bash
   kubectl apply -f nginx-pod.yaml
   ```

### 테스트하기

연동이 제대로 설정되었는지 테스트하려면:

Windows PowerShell에서:
```powershell
cd C:\Developer\infrastructure\k8s\kind
.\test-registry.ps1
```

이 스크립트는 다음을 테스트합니다:
- 레지스트리 실행 여부
- Kind 클러스터 실행 여부
- 레지스트리와 Kind 네트워크 연결 여부
- 테스트 이미지 푸시 및 사용

## 데이터 저장

레지스트리 데이터는 `./registry-data` 디렉토리에 저장됩니다. 이 디렉토리를 백업하여 데이터를 보존할 수 있습니다.

## 보안 참고 사항

이 설정은 개발 및 테스트 환경을 위한 것입니다. 프로덕션 환경에서는 HTTPS 및 인증을 구성하는 것이 좋습니다.

## 문제 해결

### 이미지 삭제 문제

이미지 삭제가 작동하지 않는 경우, 레지스트리 서비스의 환경 변수 `REGISTRY_STORAGE_DELETE_ENABLED`가 `true`로 설정되어 있는지 확인하세요.

### 연결 문제

서비스에 연결할 수 없는 경우 다음을 확인하세요:
```bash
docker-compose ps
```

모든 서비스가 실행 중인지 확인하고, 로그를 확인하세요:
```bash
docker-compose logs
```

### Kind 클러스터 연결 문제

1. 레지스트리가 kind 네트워크에 연결되어 있는지 확인:
   ```bash
   docker network inspect kind
   ```

2. 클러스터 노드에 레지스트리 설정이 제대로 적용되었는지 확인:
   ```bash
   docker exec -it local-k8s-control-plane ls -la /etc/containerd/certs.d/localhost:5000/
   ```

3. 컨테이너 실행 로그 확인:
   ```bash
   kubectl describe pod [파드명]
   ```

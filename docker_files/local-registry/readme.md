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

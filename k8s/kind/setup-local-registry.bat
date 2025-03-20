@echo off
echo 로컬 레지스트리 설정 및 kind 클러스터 연결 스크립트

REM 도커가 실행 중인지 확인
docker info > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Docker가 실행 중이지 않습니다. Docker Desktop을 실행해주세요.
  exit /b 1
)

REM 1. 로컬 레지스트리 실행
echo 1. 로컬 레지스트리 실행 상태 확인...
docker inspect -f '{{.State.Running}}' registry > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo 로컬 레지스트리가 실행 중이지 않습니다. 시작합니다...
  cd /d C:\Developer\infrastructure\docker_files\local-registry
  docker-compose up -d
  if %ERRORLEVEL% neq 0 (
    echo 레지스트리 실행 중 오류가 발생했습니다.
    exit /b 1
  )
  echo 레지스트리가 성공적으로 시작되었습니다.
  timeout /t 5 /nobreak > nul
) else (
  echo 레지스트리가 이미 실행 중입니다.
)

REM 2. kind 네트워크 생성
echo 2. kind 네트워크 확인...
docker network inspect kind > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo kind 네트워크가 존재하지 않습니다. 생성합니다...
  docker network create kind
  if %ERRORLEVEL% neq 0 (
    echo kind 네트워크 생성 중 오류가 발생했습니다.
    exit /b 1
  )
  echo kind 네트워크가 생성되었습니다.
) else (
  echo kind 네트워크가 이미 존재합니다.
)

REM 3. 기존 클러스터 확인 및 삭제
echo 3. 기존 클러스터 확인...
cd /d C:\Developer\infrastructure\k8s\kind
kind get clusters | findstr local-k8s > nul 2>&1
if %ERRORLEVEL% equ 0 (
  echo 기존 'local-k8s' 클러스터가 있습니다. 삭제합니다...
  kind delete cluster --name local-k8s
  if %ERRORLEVEL% neq 0 (
    echo 클러스터 삭제 중 오류가 발생했습니다.
    exit /b 1
  )
  echo 기존 클러스터가 삭제되었습니다.
  timeout /t 5 /nobreak > nul
)

REM 4. kind 클러스터 생성
echo 4. 클러스터 생성 중...
kind create cluster --config=cluster.yaml
if %ERRORLEVEL% neq 0 (
  echo 클러스터 생성 중 오류가 발생했습니다.
  exit /b 1
)
echo 클러스터가 성공적으로 생성되었습니다.

REM 5. 레지스트리를 클러스터 네트워크에 연결 
echo 5. 레지스트리를 클러스터에 연결합니다...

REM 레지스트리가 kind 네트워크에 연결되어 있는지 확인
docker inspect -f='{{json .NetworkSettings.Networks.kind}}' registry > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo 레지스트리를 kind 네트워크에 연결합니다...
  docker network connect kind registry
  if %ERRORLEVEL% neq 0 (
    echo 레지스트리 연결 중 오류가 발생했습니다.
    exit /b 1
  )
) else (
  echo 레지스트리가 이미 kind 네트워크에 연결되어 있습니다.
)

REM 6. 노드에 레지스트리 설정 추가
echo 6. 노드에 레지스트리 설정을 추가합니다...
powershell -ExecutionPolicy Bypass -Command "& { $registry_ip = $(docker inspect -f='{{range .NetworkSettings.Networks.kind}}{{.IPAddress}}{{end}}' registry); Write-Host \"레지스트리 IP: $registry_ip\" }"

REM 7. PowerShell 스크립트를 사용하여 나머지 설정 진행
echo 7. 레지스트리 설정을 완료합니다...
powershell -ExecutionPolicy Bypass -File "C:\Developer\infrastructure\k8s\kind\setup-registry.ps1"
if %ERRORLEVEL% neq 0 (
  echo 레지스트리 설정 중 오류가 발생했습니다.
  exit /b 1
)

REM 8. 설정 테스트 실행
echo 8. 설정 테스트를 실행합니다...
powershell -ExecutionPolicy Bypass -File "C:\Developer\infrastructure\k8s\kind\test-registry.ps1"
if %ERRORLEVEL% neq 0 (
  echo.
  echo 테스트에 실패했습니다. 문제를 확인하고 다시 시도하세요.
  exit /b 1
)

echo.
echo 모든 설정과 테스트가 완료되었습니다.
echo 레지스트리 주소: localhost:5000
echo UI 주소: http://localhost:18580
echo.
echo 이미지 사용 예시:
echo 1. 이미지 태그 지정: docker tag nginx:latest localhost:5000/nginx:latest
echo 2. 이미지 푸시: docker push localhost:5000/nginx:latest
echo 3. 이미지 사용(Pod YAML): image: localhost:5000/nginx:latest 
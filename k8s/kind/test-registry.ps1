# kind 클러스터와 로컬 레지스트리 연결 테스트 스크립트

# 컬러 출력을 위한 함수
function Write-Color {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 테스트 결과 변수
$test_passed = $true

Write-Color "Kind 클러스터와 로컬 레지스트리 연결 테스트를 시작합니다..." "Cyan"
Write-Color "=========================================================" "Cyan"

# 1. 도커 실행 여부 확인
Write-Color "`n1. 도커 실행 여부 확인..." "Yellow"
try {
    docker info | Out-Null
    Write-Color "  ✓ 도커가 실행 중입니다." "Green"
} catch {
    Write-Color "  ✗ 도커가 실행 중이지 않습니다. Docker Desktop을 실행해주세요." "Red"
    exit 1
}

# 2. 레지스트리 실행 여부 확인
Write-Color "`n2. 로컬 레지스트리 실행 여부 확인..." "Yellow"
$registry_running = $(docker inspect -f '{{.State.Running}}' registry 2>$null) -eq 'true'
if ($registry_running) {
    Write-Color "  ✓ 로컬 레지스트리가 실행 중입니다." "Green"
} else {
    Write-Color "  ✗ 로컬 레지스트리가 실행 중이지 않습니다." "Red"
    Write-Color "    레지스트리를 실행하려면 다음 명령을 사용하세요:" "Red"
    Write-Color "    cd C:\Developer\infrastructure\docker_files\local-registry; docker-compose up -d" "Red"
    exit 1
}

# 3. kind 클러스터 실행 여부 확인
Write-Color "`n3. kind 클러스터 실행 여부 확인..." "Yellow"
$clusters = $(kind get clusters 2>$null)
if ($clusters -match "local-k8s") {
    Write-Color "  ✓ kind 클러스터 'local-k8s'가 실행 중입니다." "Green"
} else {
    Write-Color "  ✗ kind 클러스터 'local-k8s'가 실행 중이지 않습니다." "Red"
    Write-Color "    클러스터를 생성하려면 다음 명령을 사용하세요:" "Red"
    Write-Color "    cd C:\Developer\infrastructure\k8s\kind; kind create cluster --config=cluster.yaml" "Red"
    exit 1
}

# 4. kind 네트워크에 레지스트리 연결 여부 확인
Write-Color "`n4. 레지스트리가 kind 네트워크에 연결되어 있는지 확인..." "Yellow"
$connected_to_kind = $(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' registry 2>$null) -ne 'null'
if ($connected_to_kind) {
    Write-Color "  ✓ 레지스트리가 kind 네트워크에 연결되어 있습니다." "Green"
} else {
    Write-Color "  ✗ 레지스트리가 kind 네트워크에 연결되어 있지 않습니다." "Red"
    Write-Color "    다음 명령으로 연결하세요:" "Red"
    Write-Color "    docker network connect kind registry" "Red"
    $test_passed = $false
    exit 1
}

# 5. 노드에 레지스트리 설정 확인
Write-Color "`n5. 노드에 레지스트리 설정 확인..." "Yellow"
$nodes = $(kind get nodes --name local-k8s)
foreach ($node in $nodes.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($node)) { continue }
    
    Write-Color "  노드 $node 설정 확인 중..." "White"
    
    # localhost:5000 설정 확인
    $hosts_file_exists = $(docker exec $node ls -la /etc/containerd/certs.d/localhost:5000/hosts.toml 2>$null)
    if ($hosts_file_exists) {
        Write-Color "    ✓ localhost:5000 설정 파일이 존재합니다." "Green"
        $hosts_content = $(docker exec $node cat /etc/containerd/certs.d/localhost:5000/hosts.toml)
        Write-Color "    호스트 설정: $hosts_content" "White"
    } else {
        Write-Color "    ✗ localhost:5000 설정 파일이 존재하지 않습니다." "Red"
        $test_passed = $false
    }
    
    # registry:5000 설정 확인
    $reg_file_exists = $(docker exec $node ls -la /etc/containerd/certs.d/registry:5000/hosts.toml 2>$null)
    if ($reg_file_exists) {
        Write-Color "    ✓ registry:5000 설정 파일이 존재합니다." "Green"
    } else {
        Write-Color "    ✗ registry:5000 설정 파일이 존재하지 않습니다." "Yellow"
    }
}

# 6. 테스트 이미지 준비 및 푸시
Write-Color "`n6. 테스트 이미지 준비 및 푸시..." "Yellow"
try {
    # nginx 이미지 풀
    Write-Color "  - nginx 이미지 다운로드 중..." "White"
    docker pull nginx:latest | Out-Null

    # 로컬 레지스트리에 태그 지정
    Write-Color "  - 이미지 태그 지정 중..." "White"
    docker tag nginx:latest localhost:5000/test-nginx:latest | Out-Null

    # 이미지 푸시
    Write-Color "  - 이미지 푸시 중..." "White"
    docker push localhost:5000/test-nginx:latest | Out-Null

    Write-Color "  ✓ 테스트 이미지가 성공적으로 푸시되었습니다." "Green"
} catch {
    Write-Color "  ✗ 이미지 푸시 중 오류가 발생했습니다: $_" "Red"
    $test_passed = $false
    exit 1
}

# 7. 레지스트리에서 이미지 확인
Write-Color "`n7. 레지스트리에서 이미지 확인..." "Yellow"
try {
    $images = $(curl -s http://localhost:5000/v2/_catalog | ConvertFrom-Json).repositories
    if ($images -contains "test-nginx") {
        Write-Color "  ✓ 레지스트리에서 테스트 이미지를 확인했습니다." "Green"
    } else {
        Write-Color "  ✗ 레지스트리에서 테스트 이미지를 찾을 수 없습니다." "Red"
        $test_passed = $false
        exit 1
    }
} catch {
    Write-Color "  ✗ 레지스트리 API 접근 중 오류가 발생했습니다: $_" "Red"
    $test_passed = $false
    exit 1
}

# 8. 테스트 Pod 생성
Write-Color "`n8. 테스트 Pod 생성..." "Yellow"

# registry:5000을 사용하는 Pod YAML 생성
$pod_yaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: test-nginx
spec:
  containers:
  - name: nginx
    image: registry:5000/test-nginx:latest
    ports:
    - containerPort: 80
"@

try {
    # 기존 Pod 삭제 (있는 경우)
    kubectl delete pod test-nginx --ignore-not-found | Out-Null
    Write-Color "  - 기존 Pod를 삭제했습니다(있는 경우)." "White"

    # 새 Pod 생성
    Write-Color "  - registry:5000을 사용하여 새 Pod를 생성합니다..." "White"
    $pod_yaml | kubectl apply -f - | Out-Null
    
    # Pod 상태 기다리기 (최대 30초)
    Write-Color "  - Pod 상태 확인 중 (최대 30초 대기)..." "White"
    $max_attempts = 6
    $pod_ok = $false
    $image_pull_error = $false
    
    for ($i = 0; $i -lt $max_attempts; $i++) {
        Start-Sleep -Seconds 5
        
        # Pod 상태 가져오기
        $status = $(kubectl get pod test-nginx -o jsonpath='{.status.phase}' 2>$null)
        $pod_status_details = $(kubectl get pod test-nginx -o jsonpath='{.status.containerStatuses[0].state}' 2>$null)
        
        # ImagePullBackOff/ErrImagePull 확인
        if ($pod_status_details -match "ImagePullBackOff|ErrImagePull") {
            $image_pull_error = $true
            break
        }
        
        if ($status -eq "Running") {
            $pod_ok = $true
            break
        }
    }
    
    # 최종 상태 확인 및 출력
    if ($image_pull_error) {
        $pod_details = $(kubectl describe pod test-nginx | Select-String -Pattern "Failed|Error|ImagePullBackOff|ErrImagePull" -Context 2,2 | Out-String)
        Write-Color "  ✗ 이미지 가져오기 오류가 발생했습니다." "Red"
        Write-Color "    오류 내용: $pod_details" "Red"
        
        # 설정 파일 내용 출력
        Write-Color "  설정 확인:" "Yellow"
        $containerd_config = $(docker exec $(kind get nodes --name local-k8s | Select-Object -First 1) cat /etc/containerd/config.toml 2>$null)
        Write-Color "  - Containerd 설정: $containerd_config" "Yellow"
        
        $test_passed = $false
    } elseif ($pod_ok) {
        Write-Color "  ✓ Pod가 정상적으로 실행 중입니다." "Green"
        
        # Pod 내부에서 테스트
        Write-Color "  - Pod 내부 테스트 중..." "White"
        $curl_result = $(kubectl exec test-nginx -- curl -s -m 3 localhost 2>$null)
        if ($curl_result -match "Welcome to nginx") {
            Write-Color "    ✓ Nginx가 Pod 내부에서 접근 가능합니다." "Green"
        } else {
            Write-Color "    ✗ Nginx가 Pod 내부에서 접근 불가능합니다." "Yellow"
        }
    } else {
        $status = $(kubectl get pod test-nginx -o jsonpath='{.status.phase}' 2>$null)
        $reason = $(kubectl get pod test-nginx -o jsonpath='{.status.containerStatuses[0].state}' 2>$null)
        Write-Color "  ✗ Pod가 실행 상태에 도달하지 못했습니다. 현재 상태: $status" "Red"
        Write-Color "    상세 정보: $reason" "Red"
        
        # 자세한 Pod 정보 출력
        $pod_details = $(kubectl describe pod test-nginx | Out-String)
        Write-Color "    Pod 상세 정보:" "Yellow"
        Write-Color "    $pod_details" "Yellow"
        
        $test_passed = $false
    }
} catch {
    Write-Color "  ✗ 테스트 Pod 생성 중 오류가 발생했습니다: $_" "Red"
    $test_passed = $false
    exit 1
}

Write-Color "`n=========================================================" "Cyan"
if ($test_passed) {
    Write-Color "✅ 모든 테스트가 성공적으로 완료되었습니다!" "Green"
    Write-Color "로컬 레지스트리와 Kind 클러스터가 올바르게 설정되었습니다." "Green"
} else {
    Write-Color "❌ 테스트가 실패했습니다!" "Red"
    Write-Color "설정을 확인하고 다시 시도하세요. 아래 단계를 참조하세요:" "Red"
    Write-Color "1. 로컬 레지스트리를 재시작합니다: docker-compose restart registry" "Yellow"
    Write-Color "2. 설정 스크립트를 다시 실행합니다: ./setup-registry.ps1" "Yellow"
    Write-Color "3. '/etc/containerd/certs.d/' 디렉토리의 설정을 확인합니다." "Yellow"
}

Write-Color "`n사용 방법:" "White"
Write-Color "1. 이미지 태그 지정: docker tag 이미지:태그 localhost:5000/이미지:태그" "White"
Write-Color "2. 이미지 푸시: docker push localhost:5000/이미지:태그" "White"
Write-Color "3. 이미지 사용(YAML):" "White"
Write-Color "   - image: registry:5000/이미지:태그" "White"
Write-Color "`n레지스트리 UI: http://localhost:18580" "White"

# 테스트 결과 반환
exit [int](!$test_passed) 
# 로컬 레지스트리와 kind 클러스터 연결 스크립트
# PowerShell 버전

# 오류 발생 시 즉시 중단
$ErrorActionPreference = "Stop"

# 1. 로컬 레지스트리가 이미 실행 중인지 확인
$reg_name = 'registry'
$reg_port = '5000'

# 레지스트리 컨테이너 상태 확인
try {
    $registry_running = $(docker inspect -f '{{.State.Running}}' $reg_name 2>$null) -eq 'true'
    if (-not $registry_running) {
        Write-Host "로컬 레지스트리가 실행 중이지 않습니다. docker-compose를 통해 실행해주세요." -ForegroundColor Red
        Write-Host "cd C:\Developer\infrastructure\docker_files\local-registry; docker-compose up -d" -ForegroundColor Red
        exit 1
    }
    Write-Host "로컬 레지스트리가 실행 중입니다." -ForegroundColor Green
} catch {
    Write-Host "레지스트리 상태 확인 중 오류가 발생했습니다: $_" -ForegroundColor Red
    Write-Host "docker-compose를 사용하여 레지스트리를 시작하세요." -ForegroundColor Red
    exit 1
}

# 2. kind 네트워크가 존재하는지 확인하고 없으면 생성
try {
    docker network inspect kind | Out-Null
    Write-Host "kind 네트워크가 이미 존재합니다." -ForegroundColor Green
} catch {
    Write-Host "kind 네트워크가 존재하지 않습니다. 생성합니다." -ForegroundColor Yellow
    docker network create kind
    Write-Host "kind 네트워크가 생성되었습니다." -ForegroundColor Green
}

# 3. kind 클러스터 생성 (기존 cluster.yaml 사용)
Write-Host "클러스터를 생성합니다..." -ForegroundColor Yellow

# 이미 있는 클러스터 확인
$existing_cluster = kind get clusters 2>$null | Where-Object { $_ -eq "local-k8s" }
if ($existing_cluster) {
    Write-Host "이미 'local-k8s' 클러스터가 존재합니다. 삭제 후 재생성합니다..." -ForegroundColor Yellow
    kind delete cluster --name local-k8s
}

# 클러스터 생성 시도
try {
    kind create cluster --config=cluster.yaml
    Write-Host "클러스터가 성공적으로 생성되었습니다." -ForegroundColor Green
} catch {
    Write-Host "클러스터 생성 중 오류가 발생했습니다: $_" -ForegroundColor Red
    exit 1
}

# 클러스터 생성 확인
$cluster_exists = $false
try {
    $clusters = kind get clusters
    if ($clusters -match "local-k8s") {
        $cluster_exists = $true
        Write-Host "클러스터가 확인되었습니다." -ForegroundColor Green
    } else {
        Write-Host "클러스터가 생성되지 않았습니다." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "클러스터 확인 중 오류가 발생했습니다: $_" -ForegroundColor Red
    exit 1
}

# 4. 노드에 레지스트리 설정 추가
if ($cluster_exists) {
    Write-Host "노드에 레지스트리 설정을 추가합니다..." -ForegroundColor Yellow
    
    # 레지스트리 IP 주소 가져오기 - 직접 kind 네트워크 정보 파싱
    $registry_ip = ""
    try {
        # JSON으로 네트워크 정보 가져오기
        $network_info = docker network inspect kind | ConvertFrom-Json
        
        # 컨테이너 정보 검색
        foreach ($container in $network_info[0].Containers.PSObject.Properties) {
            $container_data = $network_info[0].Containers.$($container.Name)
            if ($container_data.Name -eq $reg_name) {
                $registry_ip = $container_data.IPv4Address.Split('/')[0]
                break
            }
        }
        
        # 컨테이너 직접 검색 (위 방법이 실패할 경우)
        if ([string]::IsNullOrWhiteSpace($registry_ip)) {
            foreach ($container_key in $network_info[0].Containers.Keys) {
                if ($network_info[0].Containers[$container_key].Name -eq $reg_name) {
                    $registry_ip = $network_info[0].Containers[$container_key].IPv4Address.Split('/')[0]
                    break
                }
            }
        }
    } catch {
        Write-Host "네트워크 정보 파싱 중 오류: $_" -ForegroundColor Yellow
    }
    
    # 여전히 IP를 얻지 못한 경우 가장 단순한 방법 시도
    if ([string]::IsNullOrWhiteSpace($registry_ip)) {
        try {
            # docker inspect 결과를 파일로 저장 후 파싱
            docker network inspect kind > kind_network.json
            $network_content = Get-Content -Raw kind_network.json | ConvertFrom-Json
            
            # registry 컨테이너 찾기
            foreach ($container_id in $network_content[0].Containers.PSObject.Properties.Name) {
                $container = $network_content[0].Containers.$container_id
                if ($container.Name -eq $reg_name) {
                    $registry_ip = $container.IPv4Address.Split('/')[0]
                    break
                }
            }
            
            # 임시 파일 삭제
            Remove-Item -Force kind_network.json -ErrorAction SilentlyContinue
        } catch {
            Write-Host "대체 방법으로 IP 주소 가져오기 오류: $_" -ForegroundColor Yellow
        }
    }
    
    # 마지막 수단: 고정 IP 사용
    if ([string]::IsNullOrWhiteSpace($registry_ip)) {
        # 네트워크 검사 결과에서 확인된 IP 하드코딩
        $registry_ip = "172.20.0.2"
        Write-Host "IP 주소를 자동으로 찾지 못해 고정 IP를 사용합니다: $registry_ip" -ForegroundColor Yellow
    }
    
    if ([string]::IsNullOrWhiteSpace($registry_ip)) {
        Write-Host "레지스트리 IP 주소를 가져올 수 없습니다." -ForegroundColor Red
        exit 1
    }
    Write-Host "레지스트리 IP 주소: $registry_ip" -ForegroundColor Green
    
    # localhost:5000 레지스트리 설정 디렉토리
    $REGISTRY_DIR = "/etc/containerd/certs.d/localhost:${reg_port}"
    
    # 모든 노드 목록 가져오기
    $nodes = $(kind get nodes --name local-k8s)
    if (-not $nodes) {
        Write-Host "클러스터에서 노드를 찾을 수 없습니다." -ForegroundColor Red
        exit 1
    }

    foreach ($node in $nodes.Split("`n")) {
        if ([string]::IsNullOrWhiteSpace($node)) { continue }
        
        Write-Host "  노드 $node 설정 중..." -ForegroundColor Yellow
        
        # localhost:5000 레지스트리 설정
        docker exec $node mkdir -p $REGISTRY_DIR
        
        # hosts.toml 파일 생성 - HTTP 프로토콜 설정 추가 (TLS 검증 비활성화)
        $hostsToml = @"
[host."http://${registry_ip}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true

[host."http://${reg_name}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
"@
        
        $hostsToml | docker exec -i $node cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
        
        # 레지스트리 컨테이너 이름으로도 설정 (예: registry:5000)
        $registry_name_port = "${reg_name}:${reg_port}"
        $REGISTRY_NAME_DIR = "/etc/containerd/certs.d/${registry_name_port}"
        docker exec $node mkdir -p $REGISTRY_NAME_DIR
        
        $hostsTomlName = @"
[host."http://${registry_ip}:5000"]
  capabilities = ["pull", "resolve"] 
  skip_verify = true
"@
        
        $hostsTomlName | docker exec -i $node cp /dev/stdin "${REGISTRY_NAME_DIR}/hosts.toml"
        
        # 순수 IP 주소로도 설정 (예: 172.17.0.2:5000)
        $IP_REGISTRY_DIR = "/etc/containerd/certs.d/${registry_ip}:${reg_port}"
        docker exec $node mkdir -p $IP_REGISTRY_DIR
        
        $hostsTomlIP = @"
[host."http://${registry_ip}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
"@
        
        $hostsTomlIP | docker exec -i $node cp /dev/stdin "${IP_REGISTRY_DIR}/hosts.toml"
    }
    Write-Host "노드 설정이 완료되었습니다." -ForegroundColor Green
}

# 5. 레지스트리를 클러스터 네트워크에 연결
Write-Host "레지스트리를 클러스터 네트워크에 연결합니다..." -ForegroundColor Yellow
try {
    # JSON 직접 파싱으로 연결 확인
    $connected_to_kind = $false
    
    # 네트워크 정보 가져오기
    $network_info = docker network inspect kind | ConvertFrom-Json
    
    # registry 컨테이너가 이미 연결되어 있는지 확인
    foreach ($container_id in $network_info[0].Containers.PSObject.Properties.Name) {
        $container = $network_info[0].Containers.$container_id
        if ($container.Name -eq $reg_name) {
            $connected_to_kind = $true
            break
        }
    }
    
    if (-not $connected_to_kind) {
        docker network connect "kind" $reg_name
        Write-Host "레지스트리가 kind 네트워크에 연결되었습니다." -ForegroundColor Green
        
        # 잠시 대기하여 네트워크 연결 완료 대기
        Start-Sleep -Seconds 2
    } else {
        Write-Host "레지스트리가 이미 kind 네트워크에 연결되어 있습니다." -ForegroundColor Green
    }
    
    # 네트워크 연결 후 레지스트리 IP 주소 다시 확인
    $registry_kind_ip = ""
    
    # 업데이트된 네트워크 정보 가져오기
    $updated_network = docker network inspect kind | ConvertFrom-Json
    
    # 업데이트된 registry IP 주소 찾기
    foreach ($container_id in $updated_network[0].Containers.PSObject.Properties.Name) {
        $container = $updated_network[0].Containers.$container_id
        if ($container.Name -eq $reg_name) {
            $registry_kind_ip = $container.IPv4Address.Split('/')[0]
            break
        }
    }
    
    if (-not [string]::IsNullOrWhiteSpace($registry_kind_ip)) {
        Write-Host "kind 네트워크에서 레지스트리 IP: $registry_kind_ip" -ForegroundColor Green
    }
    
} catch {
    Write-Host "레지스트리 네트워크 연결 중 오류가 발생했습니다: $_" -ForegroundColor Red
    exit 1
}

# 6. 로컬 레지스트리 정보를 ConfigMap으로 등록
Write-Host "로컬 레지스트리 정보를 ConfigMap으로 등록합니다..." -ForegroundColor Yellow
try {
    $configMapYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
"@

    $configMapYaml | kubectl apply -f -
    Write-Host "ConfigMap이 성공적으로 생성되었습니다." -ForegroundColor Green
} catch {
    Write-Host "ConfigMap 생성 중 오류가 발생했습니다: $_" -ForegroundColor Red
    exit 1
}

Write-Host "로컬 레지스트리와 kind 클러스터 연결이 완료되었습니다." -ForegroundColor Green
Write-Host "레지스트리 주소:" -ForegroundColor Cyan
Write-Host "- 외부 접근: localhost:${reg_port}" -ForegroundColor Cyan
Write-Host "- Pod에서 접근: ${registry_ip}:${reg_port} 또는 ${reg_name}:${reg_port}" -ForegroundColor Cyan
Write-Host "UI 주소: http://localhost:18580" -ForegroundColor Cyan
Write-Host ""
Write-Host "이미지 사용 예시:" -ForegroundColor White
Write-Host "1. 이미지 태그 지정: docker tag nginx:latest localhost:5000/nginx:latest" -ForegroundColor White
Write-Host "2. 이미지 푸시: docker push localhost:5000/nginx:latest" -ForegroundColor White
Write-Host "3. 이미지 사용(Pod YAML): image: localhost:5000/nginx:latest" -ForegroundColor White
Write-Host ""
Write-Host "테스트 실행: ./test-registry.ps1" -ForegroundColor Yellow 
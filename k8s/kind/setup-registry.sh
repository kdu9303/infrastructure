#!/bin/sh
set -o errexit

# 1. 로컬 레지스트리가 이미 실행 중인지 확인
reg_name='registry'
reg_port='5000'

# 레지스트리 컨테이너 상태 확인
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  echo "로컬 레지스트리가 실행 중이지 않습니다. docker-compose를 통해 실행해주세요."
  echo "cd /c:/Developer/infrastructure/docker_files/local-registry && docker-compose up -d"
  exit 1
fi

# 2. kind 네트워크가 존재하는지 확인하고 없으면 생성
if ! docker network inspect kind >/dev/null 2>&1; then
  echo "kind 네트워크가 존재하지 않습니다. 생성합니다."
  docker network create kind
fi

# 3. kind 클러스터 생성 (기존 cluster.yaml 사용)
echo "클러스터를 생성합니다..."
kind create cluster --config=cluster.yaml

# 4. 노드에 레지스트리 설정 추가
echo "노드에 레지스트리 설정을 추가합니다..."
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# 5. 레지스트리를 클러스터 네트워크에 연결
echo "레지스트리를 클러스터 네트워크에 연결합니다..."
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 6. 로컬 레지스트리 정보를 ConfigMap으로 등록
echo "로컬 레지스트리 정보를 ConfigMap으로 등록합니다..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo "로컬 레지스트리와 kind 클러스터 연결이 완료되었습니다."
echo "레지스트리 주소: localhost:${reg_port}"
echo "UI 주소: http://localhost:18580"
echo ""
echo "이미지 사용 예시:"
echo "1. 이미지 태그 지정: docker tag nginx:latest localhost:5000/nginx:latest"
echo "2. 이미지 푸시: docker push localhost:5000/nginx:latest"
echo "3. 이미지 사용(Pod YAML): image: localhost:5000/nginx:latest"
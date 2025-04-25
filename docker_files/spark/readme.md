# Apache Spark with Iceberg

이 이미지는 Apache Spark와 Iceberg를 통합한 컨테이너 이미지입니다. 
Docker Compose와 Kubernetes Spark Operator 모두에서 사용 가능합니다.

## 사용 방법

### Docker Compose 환경에서 실행

```bash
# 전체 클러스터 시작 (마스터, 워커, 히스토리 서버 및 Jupyter)
docker-compose up -d

# 워커 노드 스케일링
docker-compose up --scale spark-worker=3 -d
```

### 단독 애플리케이션으로 실행

```bash
# 기본 Iceberg 테스트 애플리케이션 실행
docker run --rm -it spark-image

# 다른 기본 애플리케이션 지정
docker run --rm -it -e SPARK_APPLICATION=다른_앱.py spark-image

# 사용자 정의 Python 스크립트 실행
docker run --rm -it -v $(pwd)/my_script.py:/app/script.py spark-image application /app/script.py
```

### Kubernetes Spark Operator에서 사용

```yaml
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: iceberg-test
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: spark-image:latest
  mainApplicationFile: local:///opt/spark/bin/iceberg_conn_test.py
  env:
  - name: SPARK_APPLICATION
    value: "iceberg_conn_test.py"
  ...
```

### 빌드 시 다른 애플리케이션 지정

```bash
# Dockerfile ARG를 사용하여 다른 애플리케이션 지정
docker build -t spark-image:custom --build-arg SPARK_APPLICATION=custom_app.py .
```

# docker push
docker build -t localhost:5000/spark:0.0.3 .
docker push localhost:5000/spark:0.0.3
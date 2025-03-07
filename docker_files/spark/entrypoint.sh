#!/bin/bash

SPARK_WORKLOAD=$1
SPARK_CONFIG_TYPE=${2:-default}  # 두 번째 인자로 config 타입 받기, 기본값은 'default'

# S3/MinIO 관련 환경변수 설정 - 여기에만 정의
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=admin1234
export AWS_S3_ENDPOINT=http://minio1:9000
export AWS_REGION=us-east-1
export MINIO_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1

# 복구 디렉토리 생성
mkdir -p /opt/spark/recovery
chmod 777 /opt/spark/recovery

# 설정 파일 선택 로직
if [ "$SPARK_CONFIG_TYPE" == "hive" ]; then
  echo "Using Hive configuration (spark-defaults.conf.hive)"
  cp /opt/spark/conf/spark-defaults.conf.hive /opt/spark/conf/spark-defaults.conf
else
  echo "Using default configuration (spark-defaults.conf)"
  # 기본 설정 파일이 이미 있으므로 별도 작업 불필요
fi

echo "SPARK_WORKLOAD: $SPARK_WORKLOAD"
echo "PATH: $PATH"
echo "SPARK_HOME: $SPARK_HOME"

# 스크립트 경로 확인
ls -la $SPARK_HOME/sbin/
ls -la $SPARK_HOME/bin/

if [ "$SPARK_WORKLOAD" == "master" ];
then
  $SPARK_HOME/sbin/start-master.sh -p 7077
elif [ "$SPARK_WORKLOAD" == "worker" ];
then
  $SPARK_HOME/sbin/start-worker.sh spark://spark-master:7077
elif [ "$SPARK_WORKLOAD" == "history" ]
then
  $SPARK_HOME/sbin/start-history-server.sh
elif [ "$SPARK_WORKLOAD" == "jupyter" ]
then
  mkdir -p /opt/spark/notebooks
  cd /opt/spark/notebooks
    
  # PySpark 커널 설정
  python -m ipykernel install --user --name=pyspark --display-name="PySpark"
  # Jupyter Lab 실행
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=spark
fi



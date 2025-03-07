FROM apache/spark:3.4.4-scala2.12-java11-ubuntu

# Python 3.11 설치 및 네트워크 도구 설치
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-dev \
        python3.11-distutils \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        iputils-ping && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # 기본 Python을 3.11로 설정
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11 && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    # pip 설치
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    # 불필요한 파일 제거
    find /usr/lib/python3.11 -name '__pycache__' -type d -exec rm -rf {} +

# 버전 관리를 위한 ARG 설정 
ARG ICEBERG_VERSION=1.8.1
ARG AWS_SDK_VERSION=1.12.519
ARG HADOOP_VERSION=3.3.4

# 환경변수 설정 - 기존 Spark 이미지의 환경변수를 유지하면서 필요한 것만 추가
ENV PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:${PYTHONPATH} \
    PYSPARK_PYTHON=/usr/bin/python3 \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python3 \
    PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH

# Iceberg 런타임 및 AWS 번들 다운로드
RUN mkdir -p ${SPARK_HOME}/jars && \
    curl -Lo ${SPARK_HOME}/jars/iceberg-spark-runtime-3.4_2.12-${ICEBERG_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-spark-runtime-3.4_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-3.4_2.12-${ICEBERG_VERSION}.jar && \
    curl -Lo ${SPARK_HOME}/jars/iceberg-aws-bundle-${ICEBERG_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar && \
    curl -Lo ${SPARK_HOME}/jars/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar && \
    curl -Lo ${SPARK_HOME}/jars/httpclient5-5.3.jar \
    https://search.maven.org/remotecontent?filepath=org/apache/httpcomponents/client5/httpclient5/5.3/httpclient5-5.3.jar && \
    curl -Lo ${SPARK_HOME}/jars/hadoop-aws-${HADOOP_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar && \
    curl -Lo ${SPARK_HOME}/jars/aws-java-sdk-core-${AWS_SDK_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=com/amazonaws/aws-java-sdk-core/${AWS_SDK_VERSION}/aws-java-sdk-core-${AWS_SDK_VERSION}.jar && \
    curl -Lo ${SPARK_HOME}/jars/aws-java-sdk-s3-${AWS_SDK_VERSION}.jar \
    https://search.maven.org/remotecontent?filepath=com/amazonaws/aws-java-sdk-s3/${AWS_SDK_VERSION}/aws-java-sdk-s3-${AWS_SDK_VERSION}.jar && \
    # 작업 디렉토리 생성
    mkdir -p ${SPARK_HOME}/work-dir && \
    mkdir -p ${SPARK_HOME}/spark-events && \
    # 불필요한 Spark 파일 제거
    rm -rf ${SPARK_HOME}/examples && \
    rm -rf ${SPARK_HOME}/data && \
    find ${SPARK_HOME} -name "*.cmd" -delete && \
    # 스크립트 실행 권한 확인
    chmod +x ${SPARK_HOME}/bin/* && \
    chmod +x ${SPARK_HOME}/sbin/*

# Python 패키지 설치
COPY ./requirements.txt ${SPARK_HOME}/
RUN pip3 install --no-cache-dir -r ${SPARK_HOME}/requirements.txt && \
    rm -rf ~/.cache/pip/* && \
    # pip 캐시 및 불필요한 파일 제거
    find /usr/local/lib/python3.11 -name '__pycache__' -type d -exec rm -rf {} + && \
    find /usr/local/lib/python3.11 -name '*.pyc' -delete

# 설정 파일 및 스크립트 복사
COPY ./conf/spark-defaults.conf ${SPARK_HOME}/conf/
COPY ./conf/spark-defaults.conf.hive ${SPARK_HOME}/conf/spark-defaults.conf.hive
COPY ./entrypoint.sh ${SPARK_HOME}/

# 실행 권한 설정
RUN chmod +x ${SPARK_HOME}/entrypoint.sh

# 스크립트 경로 확인
RUN ls -la ${SPARK_HOME}/bin && \
    ls -la ${SPARK_HOME}/sbin && \
    which start-master.sh || echo "start-master.sh not found in PATH"

WORKDIR ${SPARK_HOME}/work-dir

# 기존 Spark 이미지의 ENTRYPOINT를 오버라이드
ENTRYPOINT ["tini", "--", "/opt/spark/entrypoint.sh"]
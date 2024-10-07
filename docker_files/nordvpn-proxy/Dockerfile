# docker build -t 192.168.0.17:5000/network-test:0.01 .
# docker build -t 127.0.0.1:5000/network-test:0.0.3 .
# docker push 127.0.0.1:5000/network-test:0.0.3

FROM ubuntu:latest

# 패키지 목록 업데이트 및 필요한 네트워크 도구 설치
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    iputils-ping \
    net-tools \
    traceroute \
    curl \
    wget \
    dnsutils \
    nmap \
    iptables \
    tcpdump \
    netcat-openbsd \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
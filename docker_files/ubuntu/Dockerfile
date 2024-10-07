# WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! 뜨면 컴퓨터의 C:\Users\.ssh/known_hosts 삭제
# docker-compose up -d --force-recreate

#  locate the IP address
# docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_id
# ssh -i C:\ELT_project\ubuntu-docker/.id root@127.0.0.1

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y openssh-server net-tools curl vim
RUN mkdir /var/run/sshd

RUN echo 'root:admin1234' | chpasswd

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN mkdir /root/.ssh
WORKDIR /root/.ssh
COPY .id.pub .
RUN cp .id.pub authorized_keys
RUN rm .id.pub
# RUN touch known_hosts

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
FROM ubuntu:20.04

ARG API_KEY
ARG ADMIN_PASSWORD
ARG USER_PASSWORD

COPY ./sources.list /etc/apt/sources.list
RUN apt update \
  && apt install -y vim net-tools iproute2 curl sudo cracklib-runtime wget

WORKDIR /tmp

RUN curl -s -S -o /tmp/setup.sh -sL https://deb.nodesource.com/setup_14.x \
  && chmod 755 /tmp/setup.sh \
  && /tmp/setup.sh \
  && apt-get install nodejs -y \
  && rm /tmp/setup.sh

RUN apt install -y sqlite3 python3 build-essential \
  && mkdir -p /etc/init

RUN wget https://download.01.org/intel-sgx/sgx-dcap/1.12.1/linux/distro/ubuntu20.04-server/debian_pkgs/web/sgx-dcap-pccs/sgx-dcap-pccs_1.12.101.1-focal1_amd64.deb

RUN (printf "Y\n\n\nY\n\nN\n$API_KEY\n\n$ADMIN_PASSWORD\n$ADMIN_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\nY\nCN\nSH\nSH\nIntel\nESI\nPCCS Server\n.\n\n\n") | dpkg -i sgx-dcap-pccs_1.12.101.1-focal1_amd64.deb

WORKDIR /opt/intel/sgx-dcap-pccs/

RUN groupadd -r ubuntu && useradd -r -g ubuntu ubuntu

RUN touch /usr/bin/dcap-server \
  && chmod a+x /usr/bin/dcap-server \
  && echo \#\!/bin/bash > /usr/bin/dcap-server \
  && echo "sudo chown -R ubuntu:ubuntu /opt/intel/" >> /usr/bin/dcap-server \
  && echo "node -r esm /opt/intel/sgx-dcap-pccs/pccs_server.js" >> /usr/bin/dcap-server

RUN echo "ubuntu ALL=(ALL) NOPASSWD: /usr/bin/chown -R ubuntu\:ubuntu /opt/intel/" > /etc/sudoers.d/ubuntu

USER ubuntu

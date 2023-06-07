FROM ubuntu:20.04

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /tmp

RUN apt update \
  && apt install -y curl wget build-essential cracklib-runtime \
  && curl -s -S -o /tmp/setup.sh -sL https://deb.nodesource.com/setup_14.x \
  && chmod 755 /tmp/setup.sh \
  && /tmp/setup.sh \
  && apt-get install nodejs -y \
  && rm /tmp/setup.sh

RUN wget https://download.01.org/intel-sgx/sgx-dcap/1.15/linux/distro/ubuntu20.04-server/sgx_debian_local_repo.tgz \
  && tar -xzvf sgx_debian_local_repo.tgz \
  && mv sgx_debian_local_repo/pool/main/s/sgx-dcap-pccs/sgx-dcap-pccs_1.15.100.3-focal1_amd64.deb . \
  && rm -rf sgx_debian_local_repo.tgz sgx_debian_local_repo

RUN mkdir -p /etc/init

RUN if [ $http_proxy = "" -a $https_proxy = "" ]; then (printf "Y\n\n\nN\n") | dpkg -i sgx-dcap-pccs_1.15.100.3-focal1_amd64.deb; \
  elif [ $http_proxy != "" -a $https_proxy != "" ]; then (printf "Y\nN\n") | dpkg -i sgx-dcap-pccs_1.15.100.3-focal1_amd64.deb; \
  else (printf "Y\n\nN\n") | dpkg -i sgx-dcap-pccs_1.15.100.3-focal1_amd64.deb; fi

WORKDIR /opt/intel/sgx-dcap-pccs/

RUN mkdir /opt/intel/sgx-dcap-pccs/ssl_key \
  && openssl genrsa -out ssl_key/private.pem 2048 \
  && (printf "\n\n\n\n\n\n\n\n\n") | openssl req -new -key ssl_key/private.pem -out ssl_key/csr.pem \
  && openssl x509 -req -days 365 -in ssl_key/csr.pem -signkey ssl_key/private.pem -out ssl_key/file.crt

RUN touch /usr/bin/pccs-server \
  && chmod a+x /usr/bin/pccs-server \
  && echo \#\!/bin/bash > /usr/bin/pccs-server \
  && echo "node pccs_server.js" >> /usr/bin/pccs-server

ENTRYPOINT ["pccs-server"]
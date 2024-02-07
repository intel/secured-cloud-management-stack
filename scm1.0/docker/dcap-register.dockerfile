FROM ubuntu:20.04

COPY ./sources.list /etc/apt/sources.list
RUN apt update \
  && apt install -y vim net-tools iproute2 sudo build-essential ocaml automake autoconf libtool wget python libssl-dev curl git libcurl4-openssl-dev

RUN echo 'deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main' | tee /etc/apt/sources.list.d/intel-sgx.list \
  && wget -qO - https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | apt-key add

ENV SGX_VERSION=2.15.101.1-focal1 \
    DCAP_VERSION=1.12.101.1-focal1

RUN apt update &&\
    apt-get install -y libsgx-ra-network=${DCAP_VERSION}\
                       libsgx-ra-uefi=${DCAP_VERSION} && \
    apt-get install --download-only sgx-ra-service=${DCAP_VERSION} &&\
    mkdir -p /tmp/ra_service &&\
    dpkg -X /var/cache/apt/archives/sgx-ra-service_${DCAP_VERSION}_amd64.deb /tmp/ra_service &&\
    cp /tmp/ra_service/etc/mpa_registration.conf /etc/ &&\
    cp -r /tmp/ra_service/opt/intel /opt/ &&\
    rm -rf /tmp/ra_service &&\
    rm -rf /var/cache/apt/archives/sgx-ra-service_${DCAP_VERSION}_amd64.deb /tmp/ra_service

RUN groupadd -r ubuntu && useradd -r -g ubuntu ubuntu

RUN chown -R ubuntu:ubuntu /opt/intel

RUN touch /usr/bin/dcap-register \
  && chmod a+x /usr/bin/dcap-register \
  && echo \#\!/bin/bash > /usr/bin/dcap-register \
  && echo "set -x" >> /usr/bin/dcap-register \
  && echo "sudo /opt/intel/sgx-ra-service/mpa_registration" >> /usr/bin/dcap-register \
  && echo "result=\$(sudo /opt/intel/sgx-ra-service/mpa_manage -get_last_registration_error_code)" >> /usr/bin/dcap-register \
  && echo "if [[ \"\${result}\" == \"Last reported registration error code: 0\" ]]; then exit 0; fi" >> /usr/bin/dcap-register \
  && echo "sleep infinity" >> /usr/bin/dcap-register

RUN echo "ubuntu ALL=(ALL) NOPASSWD: /opt/intel/sgx-ra-service/mpa_registration, /opt/intel/sgx-ra-service/mpa_manage" > /etc/sudoers.d/ubuntu

WORKDIR /opt/intel/sgx-ra-service/

USER ubuntu

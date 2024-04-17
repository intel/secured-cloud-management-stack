FROM ubuntu:22.04

WORKDIR /srv

ARG SGX_DEBIAN_REPO=sgx_debian_local_repo

COPY ${SGX_DEBIAN_REPO} ./${SGX_DEBIAN_REPO}

RUN echo "deb [trusted=yes arch=amd64] file:/srv/${SGX_DEBIAN_REPO} jammy main" > /etc/apt/sources.list.d/sgx_debian_local_repo.list && \
  apt-get update && apt-get install -y --no-install-recommends curl wget gnupg ca-certificates tdx-qgs libsgx-enclave-common-dev libsgx-dcap-default-qpl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN touch /usr/bin/qgs-server \
  && chmod a+x /usr/bin/qgs-server \
  && echo \#\!/bin/bash > /usr/bin/qgs-server \
  && echo "/opt/intel/tdx-qgs/qgs --no-daemon" >> /usr/bin/qgs-server

ENTRYPOINT ["qgs-server"]
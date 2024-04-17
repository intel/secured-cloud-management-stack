FROM ubuntu:22.04

WORKDIR /srv

ARG SGX_DEBIAN_REPO=sgx_debian_local_repo

COPY ${SGX_DEBIAN_REPO} ./${SGX_DEBIAN_REPO}

RUN mkdir -p /etc/init

RUN echo "deb [trusted=yes arch=amd64] file:/srv/${SGX_DEBIAN_REPO} jammy main" > /etc/apt/sources.list.d/sgx_debian_local_repo.list && \
  apt-get update && apt-get install -y --no-install-recommends curl wget gnupg ca-certificates libsgx-ra-network libsgx-ra-uefi sgx-ra-service && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN touch /usr/bin/mp-register \
  && chmod a+x /usr/bin/mp-register \
  && echo \#\!/bin/bash > /usr/bin/mp-register \
  && echo "set -x" >> /usr/bin/mp-register \
  && echo "/opt/intel/sgx-ra-service/mpa_registration" >> /usr/bin/mp-register \
  && echo "result=\$(/opt/intel/sgx-ra-service/mpa_manage -get_last_registration_error_code)" >> /usr/bin/mp-register \
  && echo "if [ \"\${result}\" = \"Last reported registration error code: 0\" ]; then exit 0; fi" >> /usr/bin/mp-register \
  && echo "sleep infinity" >> /usr/bin/mp-register

ENTRYPOINT ["mp-register"]

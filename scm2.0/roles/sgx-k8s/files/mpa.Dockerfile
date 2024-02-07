FROM ubuntu:20.04

RUN apt update && apt install -y curl gnupg-agent \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-sgx.gpg] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main" | \
    tee -a /etc/apt/sources.list.d/intel-sgx.list \
    && curl -s https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | \
    gpg --dearmor --output /usr/share/keyrings/intel-sgx.gpg \
    && apt update \
    && export DCAP_VERSION=1.15.100.3-focal1 \
    && apt-get install -y libsgx-ra-network=${DCAP_VERSION} libsgx-ra-uefi=${DCAP_VERSION} \
    && apt-get install --download-only sgx-ra-service=${DCAP_VERSION} \
    && mkdir -p /tmp/ra_service \
    && dpkg -X /var/cache/apt/archives/sgx-ra-service_${DCAP_VERSION}_amd64.deb /tmp/ra_service \
    && cp /tmp/ra_service/etc/mpa_registration.conf /etc/ \
    && cp -r /tmp/ra_service/opt/intel /opt/ \
    && rm -rf /tmp/ra_service \
    && rm -rf /var/cache/apt/archives/sgx-ra-service_${DCAP_VERSION}_amd64.deb /tmp/ra_service

RUN touch /usr/bin/mpa-tool \
  && chmod a+x /usr/bin/mpa-tool \
  && echo \#\!/bin/bash > /usr/bin/mpa-tool \
  && echo "set -x" >> /usr/bin/mpa-tool \
  && echo "/opt/intel/sgx-ra-service/mpa_registration" >> /usr/bin/mpa-tool \
  && echo "result=\$(/opt/intel/sgx-ra-service/mpa_manage -get_last_registration_error_code)" >> /usr/bin/mpa-tool \
  && echo "if [ \"\${result}\" = \"Last reported registration error code: 0\" ]; then exit 0; fi" >> /usr/bin/mpa-tool \
  && echo "sleep infinity" >> /usr/bin/mpa-tool

ENTRYPOINT ["mpa-tool"]
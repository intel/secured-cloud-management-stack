FROM ubuntu:20.04

RUN apt update && apt install -y curl gnupg-agent \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-sgx.gpg] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main" | \
    tee -a /etc/apt/sources.list.d/intel-sgx.list \
    && curl -s https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | \
    gpg --dearmor --output /usr/share/keyrings/intel-sgx.gpg \
    && apt update \
    && export SGX_VERSION="2.18.100.3-focal1" && export DCAP_VERSION="1.15.100.3-focal1" \
    && apt install -y --no-install-recommends \
       libsgx-ae-pce=${SGX_VERSION} \
       libsgx-enclave-common=${SGX_VERSION} \
       libsgx-urts=${SGX_VERSION} \
       sgx-aesm-service=${SGX_VERSION} \
       libsgx-aesm-ecdsa-plugin=${SGX_VERSION} \
       libsgx-aesm-pce-plugin=${SGX_VERSION} \
       libsgx-aesm-quote-ex-plugin=${SGX_VERSION} \
       libsgx-dcap-ql=${DCAP_VERSION} \
       libsgx-pce-logic=${DCAP_VERSION} \
       libsgx-qe3-logic=${DCAP_VERSION} \
       libsgx-ae-qe3=${DCAP_VERSION} \
       libsgx-ae-id-enclave=${DCAP_VERSION} \
       libsgx-dcap-default-qpl=${DCAP_VERSION}

RUN echo "/opt/intel/sgx-aesm-service/aesm" | tee /etc/ld.so.conf.d/sgx.conf \
    && ldconfig

ENV PATH=/opt/intel/sgx-aesm-service/aesm
ENTRYPOINT ["/opt/intel/sgx-aesm-service/aesm/aesm_service", "--no-daemon"]
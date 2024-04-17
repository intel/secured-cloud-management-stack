FROM ubuntu:20.04

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y \
    wget \
    curl \
    unzip \
    protobuf-compiler \
    libprotobuf-dev \
    build-essential \
    cmake \
    pkg-config \
    gdb \
    vim \
    python3 \
    git \
    gnupg \
    ca-certificates

# SGX SDK is installed in /opt/intel directory.
WORKDIR /opt/intel

ARG SGX_SDK_INSTALLER=sgx_linux_x64_sdk_2.18.100.3.bin

RUN curl -fsSLo /usr/share/keyrings/gramine-keyring.gpg https://packages.gramineproject.io/gramine-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gramine-keyring.gpg] https://packages.gramineproject.io/ focal main" | tee /etc/apt/sources.list.d/gramine.list \
  && curl -fsSLo /usr/share/keyrings/intel-sgx-deb.asc https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-sgx-deb.asc] https://download.01.org/intel-sgx/sgx_repo/ubuntu focal main" | tee /etc/apt/sources.list.d/intel-sgx.list \
  && apt update \
  && export SGX_VERSION="2.18.100.3-focal1" && export DCAP_VERSION="1.15.100.3-focal1" \
  && apt-get install -y --no-install-recommends \
    libsgx-headers=${SGX_VERSION} \
    libsgx-quote-ex=${SGX_VERSION} \
    libsgx-quote-ex-dev=${SGX_VERSION} \
    libsgx-enclave-common=${SGX_VERSION} \
    libsgx-enclave-common-dev=${SGX_VERSION} \
    libsgx-urts=${SGX_VERSION} \
    libsgx-launch=${SGX_VERSION} \
    libsgx-ae-pce=${SGX_VERSION} \
    libsgx-ae-qe3=${DCAP_VERSION} \
    libsgx-pce-logic=${DCAP_VERSION} \
    libsgx-qe3-logic=${DCAP_VERSION} \
    libsgx-dcap-ql=${DCAP_VERSION} \
    libsgx-dcap-ql-dev=${DCAP_VERSION} \
    libsgx-dcap-default-qpl-dev=${DCAP_VERSION} \
    libsgx-dcap-default-qpl=${DCAP_VERSION} \
    libsgx-dcap-quote-verify=${DCAP_VERSION} \
    libsgx-dcap-quote-verify-dev=${DCAP_VERSION} \
    libsgx-ae-id-enclave=${DCAP_VERSION} \
    libsgx-ae-qve=${DCAP_VERSION} \
    gramine=1.4

# Install SGX SDK
RUN wget https://download.01.org/intel-sgx/sgx-linux/2.18/distro/ubuntu20.04-server/$SGX_SDK_INSTALLER \
  && chmod +x  $SGX_SDK_INSTALLER \
  && echo "yes" | ./$SGX_SDK_INSTALLER \
  && rm $SGX_SDK_INSTALLER

RUN git clone -b DCAP_1.15 https://github.com/intel/SGXDataCenterAttestationPrimitives.git \
  && cd SGXDataCenterAttestationPrimitives/SampleCode/QuoteGenerationSample \
  && . /opt/intel/sgxsdk/environment \
  && make \
  && cd - \
  && cd SGXDataCenterAttestationPrimitives/SampleCode/QuoteVerificationSample \
  && . /opt/intel/sgxsdk/environment \
  && make SGX_DEBUG=1 \
  && cd -

RUN git clone -b v1.4 https://github.com/gramineproject/gramine.git \
  && gramine-sgx-gen-private-key

WORKDIR /opt/intel/SGXDataCenterAttestationPrimitives/SampleCode
FROM ubuntu:22.04

WORKDIR /tmp

ARG SGX_DEBIAN_REPO=sgx_debian_local_repo
ARG PCCS_PKG=sgx-dcap-pccs_1.16.90.3-jammy1_amd64.deb

COPY ${SGX_DEBIAN_REPO}/pool/main/s/sgx-dcap-pccs/${PCCS_PKG} ./${PCCS_PKG}

RUN apt-get update && apt-get install -y --no-install-recommends curl wget gnupg ca-certificates build-essential cracklib-runtime && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends nodejs && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#Deprecated: RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y --no-install-recommends nodejs

RUN mkdir -p /etc/init
RUN if [ "$http_proxy" = "" ] && [ "$https_proxy" = "" ]; then (printf "Y\n\n\nN\n") | dpkg -i ${PCCS_PKG}; \
  elif [ "$http_proxy" != "" ] && [ "$https_proxy" != "" ]; then (printf "Y\nN\n") | dpkg -i ${PCCS_PKG}; \
  else (printf "Y\n\nN\n") | dpkg -i ${PCCS_PKG}; fi

WORKDIR /opt/intel/sgx-dcap-pccs/

RUN mkdir ssl_key \
  && openssl genrsa -out ssl_key/private.pem 2048 \
  && (printf "\n\n\n\n\n\n\n\n\n") | openssl req -new -key ssl_key/private.pem -out ssl_key/csr.pem \
  && openssl x509 -req -days 365 -in ssl_key/csr.pem -signkey ssl_key/private.pem -out ssl_key/file.crt && \
  sed -i '/proxy/d' .npmrc && sed -i '/proxy/d' node_modules/ffi-napi/build/config.gypi

RUN touch /usr/bin/pccs-server \
  && chmod a+x /usr/bin/pccs-server \
  && echo \#\!/bin/bash > /usr/bin/pccs-server \
  && echo "node /opt/intel/sgx-dcap-pccs/pccs_server.js" >> /usr/bin/pccs-server

ENTRYPOINT ["pccs-server"]
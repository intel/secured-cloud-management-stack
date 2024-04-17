# Build Container Images

[Kolla](https://docs.openstack.org/kolla/latest/) is used to build container images of OpenStack Components. 
OpenStack community has pushed official release images to [Docker Hub](https://hub.docker.com/u/kolla/). 
The formats of image's name and image's tag are `<os-distribution-name>-<install-type>-<component-name>` 
and `<release-version>-<os-distribution-release-version>`, such as `centos-source-keystone` and `train-centos8`.

To enable TDX/SGX,  codes of OpenStack components are modified.
As a result, some configuration options of Kolla need to be customized.
What's more, some components of TDX/SGX Platform SoftWare (PSW) are containerized.
Container images of TDX-enabled cloud can be built as follows.

---
## Initial Environment (Redhat 8.7, root)

```bash
cd ~
cat << EOF > /etc/yum.repos.d/docker.repo
[docker]
baseurl = https://download.docker.com/linux/centos/\$releasever/\$basearch/stable
gpgcheck = 1
gpgkey = https://download.docker.com/linux/centos/gpg
name = Docker main Repository

module_hotfixes = True
EOF
yum install -y epel-release.noarch python3-pip.noarch docker-ce git wget make
systemctl start docker
pip3 install -U pip
pip install tox wheel
alternatives --set python /usr/bin/python3
```

---
## Build OpenStack Images

### Clone applications.services.cloud.confidential-computing.sgx-hmc-solution.git

```bash
cd ~
git clone https://github.com/intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
```

### Install Kolla

```bash
git clone -b train-eol https://github.com/openstack/kolla.git
```

Refer to [build-repo-redhat8.7-tdx](./build-repo-redhat8.7-tdx.md) doc to build tdx host repo. Then copy `repo/host` directory to `./kolla/docker/nova/nova-libvirt/tdx-host`.

```bash
sed -i '/bifrost-base/d' ./kolla/kolla/image/build.py
pip install ./kolla
cd kolla
tox -e genconfig
mkdir -p /etc/kolla
cp etc/kolla/kolla-build.conf /etc/kolla/
``` 

### Create Distribute Package of Nova
Merage the sgx and tdx patch to Nova source code and package it.
```bash
cd ~
git clone -b 20.6.1 https://github.com/openstack/nova.git
pushd nova
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/nova-intel-sgx.patch
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/nova-intel-tdx.patch
python3 setup.py sdist
cp dist/nova-20.6.2.dev10.tar.gz /root/
popd
```
**Note**: Pay attention to the dev index!

### Create Distribute Package of Ironic-Inspector

```bash
cd ~
git clone -b 9.2.4 https://github.com/openstack/ironic-inspector.git
pushd ironic-inspector
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/ironic-inspector-intel-sgx.patch
python3 setup.py sdist
cp dist/ironic-inspector-9.2.5.dev1.tar.gz /root/
popd
```

### Create File of template_override.j2

```bash
cat << EOF > /etc/kolla/template-override.j2
{% extends parent_template %}

{% block nova_libvirt_header %}
COPY tdx-host /srv/tdx-host
RUN echo "[tdx-host-local]" >> /etc/yum.repos.d/tdx-host-local.repo && \
    echo "name=tdx-host-local" >> /etc/yum.repos.d/tdx-host-local.repo && \
    echo "baseurl=file:///srv/tdx-host" >> /etc/yum.repos.d/tdx-host-local.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/tdx-host-local.repo && \ 
    echo "enabled=1" >> /etc/yum.repos.d/tdx-host-local.repo && \
    echo "module_hotfixes=true" >> /etc/yum.repos.d/tdx-host-local.repo
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/e/epel-release-8-19.el8.noarch.rpm
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/c/capstone-4.0.2-5.el8.x86_64.rpm     
RUN dnf remove -y qemu-kvm
RUN dnf install -y intel-mvp-tdx-qemu-kvm intel-mvp-ovmf intel-mvp-tdx-libvirt
{% endblock %}

{% block nova_libvirt_footer %}
RUN sed -i '/<\/cpus>/d' /usr/share/libvirt/cpu_map/x86_features.xml
RUN echo "" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  <!-- SGX features -->" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x07' ecx_in='0x00' ebx='0x00000004'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgxlc">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x07' ecx_in='0x00' ecx='0x40000000'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx1">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x12' ecx_in='0x00' eax='0x00000001'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx-debug">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000002'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx-mode64">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000004'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx-provisionkey">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000010'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo '  <feature name="sgx-tokenkey">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000020'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \
    echo "</cpus>" >> /usr/share/libvirt/cpu_map/x86_features.xml
{% endblock %}

{% block ironic_pxe_footer %}
RUN if [ -f /usr/share/ipxe/ipxe-$(arch).efi ]; then cp -f /usr/share/ipxe/ipxe-$(arch).efi /usr/share/ipxe/ipxe.efi; fi
{% endblock %}

EOF
```

### Set Options in /etc/kolla/kolla-build.conf
```ini
[DEFAULT]
base = centos
base_tag = stream8
base_image = quay.io/centos/centos
base_arch = x86_64
template_override = /etc/kolla/template-override.j2
install_type = source
tag = train-centos8s

[nova-base]
type = local
location = /root/nova-20.6.2.dev10.tar.gz

[ironic-inspector]
type = local
location = /root/ironic-inspector-9.2.5.dev1.tar.gz

[profiles]
default = chrony,cron,kolla-toolbox,fluentd,glance,haproxy,heat,horizon,keepalived,keystone,mariadb,memcached,neutron,nova-,placement,openvswitch,rabbitmq,bifrost,ironic-,dnsmasq,iscsid
```

### Execute Build Command

```bash
## default command
kolla-build --profile default

## if need to record log
# kolla-build --profile default --retries 3 2>&1 | tee -a kolla-build.log

```

### Build Skyline Image

#### Clone skyline-apiserver.git and skyline-console.git

```bash
cd ~
git clone https://github.com/openstack/skyline-console.git
git clone https://github.com/openstack/skyline-apiserver.git
```

#### Apply patch to Skyline-Console

```bash
cd ~/skyline-console
git reset --hard 3544b35a5b78495799dc9b0b2460a046899af84b
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/skyline-console-intel-sgx.patch
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/skyline-console-intel-tdx.patch
cd ~/skyline-apiserver
git reset --hard 22a2895ba96bebc856bbca503258fa13411aa519
```

#### Create Distribute Package of Skyline-Console

```bash
cd ~
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/1.1.15/get-poetry.py | python - --version 1.1.15
source  $HOME/.poetry/env
wget -P /root/ --tries=10 --retry-connrefused --waitretry=60 --no-dns-cache --no-cache  https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh
bash /root/install.sh
. /root/.nvm/nvm.sh
NODE_VERSION=erbium
nvm install --lts=$NODE_VERSION
nvm alias default lts/$NODE_VERSION
nvm use default
npm install -g yarn
cd skyline-console
make install
make package
```

#### Custom Config for Build

```bash
cd ~
mv skyline-console/dist/skyline-console-*.tar.gz skyline-apiserver/skyline-console-master.tar.gz
cp skyline-apiserver/skyline-console-master.tar.gz skyline-apiserver/skyline_apiserver/skyline-console-master.tar.gz
cd skyline-apiserver/
sed -i 's/wget \$(SKYLINE_CONSOLE_PACKAGE_URL) &&//g' Makefile
sed -i 's/\${SKYLINE_CONSOLE_PACKAGE_URL}/\/skyline-apiserver\/skyline-console-master.tar.gz/g' container/Dockerfile
sed -i 's/httpx>=0.16.1/httpx==0.23.0/' requirements.txt
sed -i 's/SQLAlchemy>=1.3.24/SQLAlchemy==1.4.39/' requirements.txt
```

#### Execute Build Command

```bash
cd ~/skyline-apiserver
make build IMAGE=kolla/centos-source-skyline IMAGE_TAG=train-centos8s BUILD_ARGS="--build-arg http_proxy=<http proxy> --build-arg https_proxy=<https proxy>"
```

---
## Build SGX/TDX PSW Images

Download dcap-20230406.tar.gz from RDC, decompress it and also decompress dcap-20230406/Ubuntu22.04/sgx_debian_local_repo.tar.gz, then put sgx_debian_local_repo directory into applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/docker/.

### Build image of Provisioning Certificate Caching Service (PCCS)

```bash
cd ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/docker
docker build -f pccs-server.Dockerfile -t custom/pccs-server:latest \
  --build-arg http_proxy=<http proxy> \
  --build-arg https_proxy=<https_proxy> .
```

### Build image of Multi-package Registration Agent (MPA)

```bash
cd ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/docker
docker build -f mp-register.Dockerfile -t custom/mp-register:latest \
  --build-arg http_proxy=<http proxy> \
  --build-arg https_proxy=<https_proxy> .
```

### Build image of TDX Quote Generation Service (QGS)
```bash
cd ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/docker
docker build -f qgs-server.Dockerfile -t custom/qgs-server:latest \
  --build-arg http_proxy=<http proxy> \
  --build-arg https_proxy=<https_proxy> .
```

---
## Save Images to a File

```bash
docker save $(docker images --format '{{.Repository}}:{{.Tag}}' | grep kolla) -o openstack-train.tar
docker save $(docker images --format '{{.Repository}}:{{.Tag}}' | grep custom) -o dcap.tar
```

# Build Container Images

[Kolla](https://docs.openstack.org/kolla/latest/) is used to build container images of OpenStack Components. 
OpenStack community has pushed official release images to [Docker Hub](https://hub.docker.com/u/kolla/). 
The formats of image's name and image's tag are `<os-distribution-name>-<install-type>-<component-name>` 
and `<release-version>-<os-distribution-release-version>`, such as `centos-source-keystone` and `train-centos8`.

To enable SGX,  codes of OpenStack components are modified.
As a result, some configuration options of Kolla need to be customized.
What's more, some components of SGX Platform SoftWare (PSW) are containerized.
Container images of SGX-enabled cloud can be built as follows.

## Initial Environment (CentOS 8.4, root)

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

## Build OpenStack Images

### Clone applications.services.cloud.confidential-computing.sgx-hmc-solution.git

```bash
cd ~
git clone git@github.com:intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
```

### Install Kolla

```bash
git clone -b stable/train https://opendev.org/openstack/kolla.git
sed -i '/bifrost-base/d' ./kolla/kolla/image/build.py
pip install ./kolla
cd kolla
tox -e genconfig
mkdir -p /etc/kolla
cp etc/kolla/kolla-build.conf /etc/kolla/
```

### Create Distribute Package of Nova

```bash
cd ~
git clone -b 20.6.1 https://opendev.org/openstack/nova.git
pushd nova
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/nova-intel-sgx.patch
python3 setup.py sdist
cp dist/nova-20.6.2.dev4.tar.gz /root/
popd
```

### Create Distribute Package of Ironic-Inspector

```bash
cd ~
git clone -b 9.2.4 https://opendev.org/openstack/ironic-inspector.git
pushd ironic-inspector
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/ironic-inspector-intel-sgx.patch
python3 setup.py sdist
cp dist/ironic-inspector-9.2.5.dev1.tar.gz /root/
popd
```

### Create File of template_override.j2

```bash
cat << EOF > /etc/kolla/template-override.j2
{% extends parent_template %}

{% block nova_libvirt_header %}
RUN curl -o /etc/yum.repos.d/intelsgxstack.repo https://download.01.org/intelsgxstack/2021-12-08/rhel/intelsgxstack.repo
RUN dnf install -y qemu-kvm-6.2.0-mvp1.el8
{% endblock %}

{% block nova_libvirt_footer %}
RUN sed -i '/<\/cpus>/d' /usr/share/libvirt/cpu_map/x86_features.xml
RUN echo "" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  <!-- SGX features -->" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x07' ecx_in='0x00' ebx='0x00000004'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgxlc">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x07' ecx_in='0x00' ecx='0x40000000'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx1">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x12' ecx_in='0x00' eax='0x00000001'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx-debug">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000002'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx-mode64">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000004'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx-provisionkey">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000010'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo '  <feature name="sgx-tokenkey">' >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "    <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000020'/>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "  </feature>" >> /usr/share/libvirt/cpu_map/x86_features.xml && \\
    echo "</cpus>" >> /usr/share/libvirt/cpu_map/x86_features.xml
{% endblock %}

{% block ironic_pxe_footer %}
RUN if [ -f /usr/share/ipxe/ipxe-\$(arch).efi ]; then cp -f /usr/share/ipxe/ipxe-\$(arch).efi /usr/share/ipxe/ipxe.efi; fi
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
location = /root/nova-20.6.1.tar.gz

[ironic-inspector]
type = local
location = /root/ironic-inspector-9.2.5.dev1.tar.gz

[profiles]
default = chrony,cron,kolla-toolbox,fluentd,glance,haproxy,heat,horizon,keepalived,keystone,mariadb,memcached,neutron,nova-,placement,openvswitch,rabbitmq,bifrost,ironic-,dnsmasq,iscsid
```

### Execute Build Command

```bash
kolla-build --profile default
```

## Build SGX PSW Images

### Build image of Provisioning Certificate Caching Service (PCCS)

API key can be obtained by following [SGX Extensions Data Center Attestation Primitives](https://www.intel.com/content/www/us/en/developer/articles/guide/intel-software-guard-extensions-data-center-attestation-primitives-quick-install-guide.html).

```bash
cd ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/docker
docker build -f dcap-server.dockerfile -t custom/dcap-server:latest \
  --build-arg http_proxy=<http proxy> \
  --build-arg https_proxy=<https_proxy> \
  --build-arg API_KEY=<api key of intel> \
  --build-arg ADMIN_PASSWORD=<custom password of admin> \
  --build-arg USER_PASSWORD=<custom password of user> .
```

### Build image of Multi-package Registration Agent (MPA)

```bash
cd ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/docker
docker build -f dcap-register.dockerfile -t custom/dcap-register:latest .
```

## Build Skyline Image

### Clone skyline-apiserver.git and skyline-console.git

```bash
cd ~
git clone https://opendev.org/openstack/skyline-console.git
git clone https://opendev.org/openstack/skyline-apiserver.git
```

### Apply patch to skyline-console

```bash
cd ~/skyline-console
git reset --hard 3544b35a5b78495799dc9b0b2460a046899af84b
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/skyline-console-intel-sgx.patch
```

### Create Distribute Package of Skyline-Console

```bash
cd ~
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
source  $HOME/.poetry/env
wget -P /root/ --tries=10 --retry-connrefused --waitretry=60 --no-dns-cache --no-cache  https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh
bash /root/install.sh
. /root/.nvm/nvm.sh
NODE_VERSION=erbium
nvm install --lts=$NODE_VERSION
nvm alias default lts/$NODE_VERSION
nvm use default
npm install -g yarn
cd skyline_console
make install
make package
```

### Custom Config for Build

```bash
cd ~
mv skyline-console/dist/skyline-console-*.tar.gz skyline-apiserver/skyline-console-master.tar.gz
cp skyline-apiserver/skyline-console-master.tar.gz skyline-apiserver/skyline_apiserver/skyline-console-master.tar.gz
cd skyline-apiserver/
sed -i 's/^SKYLINE_CONSOLE_PACKAGE_URL ?=.*//g' Makefile
sed -i 's/wget \$(SKYLINE_CONSOLE_PACKAGE_URL) &&//g' Makefile
sed -i 's/--build-arg SKYLINE_CONSOLE_PACKAGE_URL=\$(SKYLINE_CONSOLE_PACKAGE_URL)//g' Makefile
sed -i 's/\${SKYLINE_CONSOLE_PACKAGE_URL}/\/skyline-apiserver\/skyline-console-master.tar.gz/g' container/Dockerfile
```

### Execute Build Command

```bash
cd ~/skyline-apiserver
make build IMAGE=kolla/centos-source-skyline IMAGE_TAG=train-centos8s
```

## Save Images to a File

```bash
docker save $(docker images --format '{{.Repository}}:{{.Tag}}') -o openstack-train-intel-sgx.tar
```

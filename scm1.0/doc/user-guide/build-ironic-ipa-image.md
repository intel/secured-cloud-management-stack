# Build Ironic IPA Image

[Ironic Python Agent (IPA)](https://docs.openstack.org/ironic-python-agent/train/) 
image is used by Ironic and Ironic Inspector to deploy and inspect bare metal nodes.
It can be built by [Ironic Python Agent Builder](https://docs.openstack.org/ironic-python-agent-builder/latest/)
which relies on diskimage-builder. Host OS used to build IPA image is Ubuntu 20.04. 

## Install necessary tools

```bash
cat << EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
EOF
apt update
apt install -y qemu-utils python3-virtualenv git
```

## Clone applications.services.cloud.confidential-computing.sgx-hmc-solution.git

```bash
cd ~
git clone https://github.com/intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
```

## Create virtual env

```bash
cd ~
virtualenv -p /usr/bin/python3 .venv
source .venv/bin/activate
```

## Install Ironic-Python-Agent-Builder

```bash
cd ~
git clone -b 2.7.0 https://github.com/openstack/ironic-python-agent-builder.git
cd ironic-python-agent-builder
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/ironic-python-agent-builder-intel-sgx.patch
pip install .
```

## Reinstall Diskimage-Builder

```bash
cd ~ 
git clone -b 3.20.3 https://@github.com/openstack/diskimage-builder.git
cd diskimage-builder
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/dib-intel-sgx.patch
pip install .
```

## Clone Ironic-Python-Agent

```bash
cd ~
git clone -b 5.0.4 https://github.com/openstack/ironic-python-agent.git
cd ironic-python-agent
git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/ironic-python-agent-intel-sgx.patch
```

## Config Ironic-Python-Agent-Builder

```bash
cd ~
echo 'ironic-python-agent local /tmp/ironic-python-agent /root/ironic-python-agent' > ~/.venv/share/ironic-python-agent-builder/dib/ironic-python-agent-ramdisk/source-repository-ironic-python-agent
```

## Execute build script

```bash
export DIB_REPOREF_ironic_lib=stable/train
export DIB_DEBUG_TRACE=1
export DIB_REPOREF_requirements=stable/train
export DIB_PYTHON_VERSION=3
ironic-python-agent-builder -o ipa --release 7 centos -e epel
```

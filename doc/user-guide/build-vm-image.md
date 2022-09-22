# Build VM Image

VM images mean that we use these images to create virtual instances from cloud platform.

We will build centos 8.3, centos 8.4, ubuntu 18.04 and ubuntu 20.04 vm images.

**Table of contents**

- [Build VM Image](#build-vm-image)
  - [Prepare](#prepare)
  - [Build CentOS 8.3 VM Image](#build-centos-83-vm-image)
  - [Build CentOS 8.4 VM Image](#build-centos-84-vm-image)
  - [Build Ubuntu 18.04 VM Image](#build-ubuntu-1804-vm-image)
  - [Build Ubuntu 20.04 VM Image](#build-ubuntu-2004-vm-image)

## Prepare

We should install the build image tool diskimage-builder.

OS: Ubuntu 20.04

```console
root@ubuntu:~# apt update
root@ubuntu:~# apt install -y python3-virtualenv git
root@ubuntu:~# git clone git@github.com:intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
root@ubuntu:~# cd applications.services.cloud.confidential-computing.sgx-hmc-solution
root@ubuntu:~# git clone git@github.com:openstack/diskimage-builder.git
root@ubuntu:~# cd diskimage-builder
root@ubuntu:~# git checkout 3.20.3
root@ubuntu:~# git am ../dib-intel-sgx.patch
root@ubuntu:~# virtualenv -p /usr/bin/python3 .venv
root@ubuntu:~# source .venv/bin/activate
(.venv) root@ubuntu:~# pip install -e .
```

## Build CentOS 8.3 VM Image

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=8
(.venv) root@ubuntu:~# export DIB_FLAVOR=GenericCloud-8.3.2011
(.venv) root@ubuntu:~# export DIB_DISTRIBUTION_MIRROR=http://mirrors.aliyun.com/centos-vault/8.3.2011
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o centos-8-3 centos vm cloud-init dhcp-all-interfaces intel-sgx
```

## Build CentOS 8.4 VM Image

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=8
(.venv) root@ubuntu:~# export DIB_FLAVOR=GenericCloud-8.4.2105
(.venv) root@ubuntu:~# export DIB_DISTRIBUTION_MIRROR=http://mirrors.aliyun.com/centos-vault/8.4.2105
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o centos-8-4 centos vm cloud-init dhcp-all-interfaces intel-sgx
```

## Build Ubuntu 18.04 VM Image

Refer [kernel](./kernel.md) doc to fetch the kernel binary packages. Then copy
all binary packages into one folder `/tmp/kernel/deb`.

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=bionic
(.venv) root@ubuntu:~# export DIB_KERNEL_PATH=/tmp/kernel/deb
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o ubuntu-18.04 ubuntu vm cloud-init dhcp-all-interfaces intel-sgx
```

## Build Ubuntu 20.04 VM Image

Refer [kernel](./kernel.md) doc to build the kernel binary packages. Then copy
all binary packages into one folder `/tmp/kernel/deb`.

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=focal
(.venv) root@ubuntu:~# export DIB_KERNEL_PATH=/tmp/kernel/deb
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o ubuntu-20.04 ubuntu vm cloud-init dhcp-all-interfaces intel-sgx
```

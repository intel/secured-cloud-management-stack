# Build Host Image

Host images mean that we use these images to deploy host server for cloud platform.

We will build centos 7.9 and centos 8.4 host images.

**Table of contents**

- [Build Host Image](#build-host-image)
  - [Prepare](#prepare)
  - [Build CentOS 7.9 Host Image](#build-centos-79-host-image)
  - [Build CentOS 8.4 Host Image](#build-centos-84-host-image)

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

## Build CentOS 7.9 Host Image

Refer [kernel](./kernel.md) doc to build the kernel binary packages. Then copy
`kernel-ml`, `kernel-ml-devel` and `kernel-ml-headers` binary packages into
one folder `/tmp/kernel/rpm`.

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=7
(.venv) root@ubuntu:~# export DIB_KERNEL_PATH=/tmp/kernel/rpm
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o centos-7-9-uefi centos vm cloud-init block-device-efi intel-sgx
```

## Build CentOS 8.4 Host Image

```console
(.venv) root@ubuntu:~# export DIB_RELEASE=8
(.venv) root@ubuntu:~# export DIB_FLAVOR=GenericCloud-8.4.2105
(.venv) root@ubuntu:~# export DIB_DISTRIBUTION_MIRROR=http://mirrors.aliyun.com/centos-vault/8.4.2105
(.venv) root@ubuntu:~# export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, None"
(.venv) root@ubuntu:~# disk-image-create -a amd64 -t raw -o centos-8-4-uefi centos vm cloud-init block-device-efi intel-sgx
```

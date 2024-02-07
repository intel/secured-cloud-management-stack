# SCM V1.0

## User Guide

### BIOS Configuration
  Please enable SGX BIOS option on Xeon Platfrom at first. Refer to [SGX BIOS Configuration](./doc/user-guide/bios_config.md)

### Deployment Script
  You can deploy our SCM OpenStack Infrasture Stack with SGX VM instance based on our script **deploy.sh**

### Build OS Images
In this section, you need to build OS images for host, VM, BM and Ironic-Python-Agent.

* **Build Host Image**

  If you want to build CentOS 7.9 image, you need to follow the [build-kernel](./doc/user-guide/kernel.md) guide to build the kernel binary packages first.

  Then follow [build-host-image](./doc/user-guide/build-host-image.md) guide to build host images with SGX.

* **Build VM Image**

  If you want to build Ubuntu 18.04 / 20.04 images, you need to follow the [build-kernel](./doc/user-guide/kernel.md) guide to build the kernel binary packages first.

  Then follow [build-vm-image](./doc/user-guide/build-vm-image.md) guide to build VM images with SGX.

* **Build BM Image**

  If you want to build Ubuntu 18.04 / 20.04 images, you need to follow the [build-kernel](./doc/user-guide/kernel.md) guide to build the kernel binary packages first.

  Then follow [build-baremetal-image](./doc/user-guide/build-baremetal-image.md) guide to build BM images with SGX.

* **Build Ironic-Python-Agent Image**

  Follow [build-ironic-ipa-image](./doc/user-guide/build-ironic-ipa-image.md) guide to build Ironic-Python-Agent image.

### Build Docker Images

Follow [build-docker-image](./doc/user-guide/build-docker-image.md) guide to build Docker images.

### Deploy SGX-enabled Cloud

Follow [cloud-deploy](./doc/user-guide/cloud_deploy.md) guide to deploy a SGX-enabled cloud.

### Create SGX-enabled Instance

Follow [instance-create](./doc/user-guide/instance_create.md) guide to create SGX-enabled instances.

## Developer Guide

- [Diskimage Builder](./doc/developer-guide/diskimage-builder.md)
- [Nova](./doc/developer-guide/nova.md)
- [Ironic](./doc/developer-guide/ironic.md)
- [Kolla Ansible](./doc/developer-guide/kolla-ansible.md)
- [Python Nova Client](./doc/developer-guide/python-novaclient.md)
- [Python OpenStack Client](./doc/developer-guide/python-openstackclient.md)
- [Skyline](./doc/developer-guide/skyline.md)

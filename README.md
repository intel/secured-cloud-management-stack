# Secured Cloud Management Stack 1.0 (SCM)
[![OpenStack](https://img.shields.io/badge/openstack-train-blue.svg?logo=openstack)](https://www.openstack.org/software/train/)
[![SGX](https://img.shields.io/badge/SGX-2.15.1-blue.svg)](https://github.com/intel/linux-sgx/tree/sgx_2.15.1)
[![SGX DCAP](https://img.shields.io/badge/SGX%20DCAP-1.12.1-blue.svg)](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/DCAP_1.12.1)
[![License](https://img.shields.io/badge/License-Apache%202.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)

Secured Cloud Management Stack aims to enable confidential computing from infrastructure level, provide chip-level data protection capability, and enhance security for cloud computing platform. With SCM, users could make the applications run in a secured virtual machine (VM) or bare metal (BM) environment which are protected by [Intel® Software Guard Extensions (SGX)](https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html). And SCM could be applied widely in on-premise cloud and hybrid cloud owe to its excellent protection capability and flexibility.

[Intel® Software Guard Extensions (SGX)](https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html) as a key [Trusted Execution Environment (TEE)](https://en.wikipedia.org/wiki/Trusted_execution_environment) technology, is enabled in our current version. We know typical security measures may assist data at rest and in transit, but often fall short of protecting data while it is actively used in memory. Intel SGX helps protect data in use via application isolation technology. SGX offers hardware-based memory encryption that isolates code and data of specific application in memory. SGX allows user-level code to allocate private regions of memory, called enclaves, which are designed to be protected from processes running at higher privilege levels. 	

[OpenStack](https://opendev.org/openstack) as a very inflenced open source cloud computing platform, is adopted as IaaS foundation in SCM with its [Train](https://www.openstack.org/software/train/) release. SCM makes modifications to different OpenStack components to achieve the SGX enablement in different dimensions and capabilities:
- Automatic SGX capability inspection and SGX nodes discovery;
- SGX capability pass-through to VM and BM;
- SGX EPC resource management;
- SGX VM and BM instance management;

SCM provides automatic deployment for secured cloud with SGX, we use [Kayobe](https://github.com/openstack/kayobe/tree/train-eol) as the deployment tool, a framework which could enable deployment of containerised OpenStack to bare metal. For more information please refer to [Kayobe documentation](https://docs.openstack.org/kayobe/train/).

All modifications are made in patch format. These patches could also be a thorough reference for other OpenStack-like cloud computing platform.

Our current supported OS matrix is as follows.
| Host | VM | BM |
| :-: | :-: | :-: |
| CentOS 7.9 / CentOS 8.4 | CentOS 8.3 / CentOS 8.4 / Ubuntu 18.04 / Ubuntu 20.04 | CentOS 8.3 / CentOS 8.4 / Ubuntu 18.04 / Ubuntu 20.04 |

In the future, we will support more OS types.

## User Guide

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

## How to Contribute to Our Stack

Customized development of OpenStack component based on a specified branch or tag
is submitted to this repo in the form of patch.
The whole development process is as follows.

1. Clone this repo.

2. Clone OpenStack component and check out to the specified branch or tag.

3. Apply component's patch in this repo by `git am <patch-file>` if it exists.

4. Complete development.

5. Format new patch by `git format-patch -<num> --stdout > <patch-file>`.

    *Note: num is the number of commits which contains origin patch's commits and new commits.*

6. Override component's patch in this repo with newly generated patch.

7. Push to upstream.



## Future Work
Currently, we release our SCM 1.0 version; In the future, we will continue to dedicate to work on subsequent versions. We will introduce kubernetes architecture into our stack integrating with SGX for SCM 2.0, and [Intel® Trust Domain Extensions (TDX)](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-trust-domain-extensions.html) which is the next generation Intel's Trusted Execution Environment (TEE), introducing new, architectural elements to help deploy hardware-isolated, VMs called trust domains (TDs), will be integrated into our third version SCM 3.0

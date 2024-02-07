# SCM V3.0

## User Guide

### BIOS Configuration
Please enable SGX BIOS option on Xeon Platfrom at first. Refer to [SGX/TDX BIOS Configuration](./doc/user-guide/bios_config.md).

### Build TDX Related Dependices
Build the TDX software dependies for differnt OS: [Redhat 8.7](./doc/user-guide/build-repo-redhat8.7-tdx.md) and [Ubuntu 22.04](./doc/user-guide/build-repo-ubuntu22.04-tdx.md). More details can refer to [tdx-tools](https://github.com/intel/tdx-tools/blob/2023ww15/build/rhel-8/README.md)

### Deployment Script
Deploy SCM 3.0 OpenStack Infrasture Stack with SGX/TDX VM instance based on our script **deploy.sh**

### Build TDX VM Images

Refer  [build-vm-image](./doc/user-guide/build-vm-image-tdx.md) guide to build VM images with TDX.

### Build Docker Images

Follow [build-docker-image](./doc/user-guide/build-docker-image-tdx.md) guide to build Docker images.


## Developer Guide

- [Diskimage Builder](./doc/developer-guide/diskimage-builder.md)
- [Nova](../scm1.0/doc/developer-guide/nova.md)
- [Ironic](../scm1.0/doc/developer-guide/ironic.md)
- [Kolla Ansible](../scm1.0/doc/developer-guide/kolla-ansible.md)
- [Python Nova Client](../scm1.0/scm1.0/doc/developer-guide/python-novaclient.md)
- [Python OpenStack Client](../scm1.0/doc/developer-guide/python-openstackclient.md)
- [Skyline](../scm1.0/doc/developer-guide/skyline.md)

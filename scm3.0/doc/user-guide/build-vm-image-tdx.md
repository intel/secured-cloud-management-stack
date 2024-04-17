# Build VM Image

VM images mean that we use these images to create virtual instances from cloud platform.

We will build ubuntu 22.04 td-vm images.

**Table of contents**

- [Build VM Image](#build-vm-image)
  - [Prepare](#prepare)
  - [Build Ubuntu 22.04 VM Image](#build-ubuntu-2204-vm-image)
  - [Build RedHat 8.7 VM Image](#build-redhat-87-vm-image)

## Prepare

We should install the build image tool diskimage-builder.

```
git clone https://github.com/intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
git clone -b 3.20.3 https://github.com/openstack/diskimage-builder.git
cd diskimage-builder
git am ../applications.services.cloud.confidential-computing.sgx-hmc-solution/scm1.0/dib-intel-sgx.patch
git am ../applications.services.cloud.confidential-computing.sgx-hmc-solution/scm3.0/dib-intel-tdx.patch
virtualenv -p /usr/bin/python3 .venv
source .venv/bin/activate
pip install -U pip setuptools
pip install -e .
```

## Build Ubuntu 22.04 VM Image

Refer to [build-repo-ubuntu22.04-tdx](./build-repo-ubuntu22.04-tdx.md) doc to build guest repo packages. Then copy `guest_repo` directory to one folder `/tmp/kernel/guest_repo`.

```code:: bash
  # Example For Ubuntu 22.04
  export DIB_RELEASE=jammy
  export DIB_KERNEL_PATH=/tmp/kernel/guest_repo
  disk-image-create -a amd64 -t raw -o td-guest-ubuntu-22.04 ubuntu vm cloud-init block-device-efi dhcp-all-interfaces intel-tdx
```

## Build Redhat 8.7 VM Image

Refer to [build-repo-redhat8.7-tdx](./build-repo-redhat8.7-tdx.md) doc to build guest repo packages. Then copy `repo/guest` directory to one folder `/tmp/kernel/guest`.

For license requirement, user can download RHEL 8.7 cloud image from [redhat download](https://access.redhat.com/downloads).

``` code:: bash
  # Example For Redhat 8.7
  export DIB_RELEASE=8
  export DIB_YUM_REPO_CONF=/tmp/rhel8.repo
  export DIB_KERNEL_PATH=/tmp/kernel/guest
  export DIB_LOCAL_IMAGE=<path>/rhel-guest-image-8.7-1660.x86_64.qcow2
  disk-image-create -a amd64 -t raw -o td-guest-redhat-8.7 rhel vm cloud-init block-device-efi dhcp-all-interfaces intel-tdx
```
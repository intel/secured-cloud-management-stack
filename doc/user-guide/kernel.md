# Build Kernel With SGX

We will build kernel binary packages with sgx for centos 7.9, ubuntu 18.04 and ubuntu 20.04.

**Table of contents**

- [Build Kernel With SGX](#build-kernel-with-sgx)
  - [CentOS 7.9](#centos-79)
    - [Prepare](#prepare)
    - [Build Image](#build-image)
  - [Ubuntu 18.04](#ubuntu-1804)
    - [Prepare](#prepare-1)
    - [Build Image](#build-image-1)
  - [Ubuntu 20.04](#ubuntu-2004)
    - [Prepare](#prepare-2)
    - [Build Image](#build-image-2)

## CentOS 7.9

### Prepare

OS: CentOS 7.9

### Build Image

```consle
[root@centos7-9 ~]# wget http://mirror.hoztnode.net/elrepo/kernel/el7/SRPMS/kernel-ml-5.16.12-1.el7.elrepo.nosrc.rpm
[root@centos7-9 ~]# rpm -ivh kernel-ml-5.16.12-1.el7.elrepo.nosrc.rpm
[root@centos7-9 ~]# cd ~/rpmbuild/SOURCES
[root@centos7-9 SOURCES]# wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.12.tar.xz
[root@centos7-9 SOURCES]# echo "CONFIG_X86_SGX=y" >>config-5.16.12-x86_64
[root@centos7-9 SOURCES]# echo "CONFIG_X86_SGX_KVM=y" >>config-5.16.12-x86_64
[root@centos7-9 SOURCES]# yum install -y centos-release-scl centos-release-scl-rh
[root@centos7-9 SOURCES]# yum install -y openssl-devel xz-devel zlib-devel ncurses-devel python3 devtoolset-9-gcc devtoolset-9-binutils devtoolset-9-runtime asciidoc elfutils-libelf-devel newt-devel xmlto audit-libs-devel binutils-devel elfutils-devel java-1.8.0-openjdk-devel libcap-devel numactl-devel python-devel slang-devel pciutils-devel perl-ExtUtils-Embed rsync git rpm-build bison gcc net-tools
[root@centos7-9 SOURCES]# cd ~/rpmbuild
[root@centos7-9 rpmbuild]# rpmbuild -bb SPECS/kernel-ml-5.16.spec
```

**After running command `rpmbuild -bb SPECS/kernel-ml-5.16.spec`, we will wait the building to finish.**
**At last, we can find the kernel binary packages under `~/rpmbuild/RPMS/x86_64/`.**
**We need kernel-ml, kernel-ml-devel and kernel-ml-headers.**

```text
kernel-ml-5.16.12-1.el7.x86_64.rpm
kernel-ml-devel-5.16.12-1.el7.x86_64.rpm
kernel-ml-headers-5.16.12-1.el7.x86_64.rpm
```

## Ubuntu 18.04

### Prepare

OS: Ubuntu 18.04

### Build Image

```console
root@build-kernel:~# add-apt-repository ppa:cappelikan/ppa -y
root@build-kernel:~# apt-get update
root@build-kernel:~# apt-get install -y zstd
root@build-kernel:~# apt install -y mainline
// After we run the next command, we will see many print information.
// We will see the related information "dpkg-deb: building package".
// After the "dpkg-deb" finished and print other information, we should press
// the key "Ctrl + C" to stop the process for mainline to install the kernel.
// We just use mainline to compile the kernel packages.
root@build-kernel:~# mainline --install 5.13.4
```

**At last, we can find the kernel binary packages under `$HOME/.cache/mainline/5.13.4/amd64`.**

```text
linux-image-unsigned-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-modules-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-headers-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-headers-5.13.4-051304_5.13.4-051304.202107201535_all.deb
```

## Ubuntu 20.04

### Prepare

OS: Ubuntu 20.04

### Build Image

```console
root@build-kernel:~# add-apt-repository ppa:cappelikan/ppa -y
root@build-kernel:~# apt-get update
root@build-kernel:~# apt install -y mainline
// After we run the next command, we will see many print information.
// We will see the related information "dpkg-deb: building package".
// After the "dpkg-deb" finished and print other information, we should press
// the key "Ctrl + C" to stop the process for mainline to install the kernel.
// We just use mainline to compile the kernel packages.
root@build-kernel:~# mainline --install 5.13.4
```

**At last, we can find the kernel binary packages under `$HOME/.cache/mainline/5.13.4/amd64`.**

```text
linux-image-unsigned-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-modules-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-headers-5.13.4-051304-generic_5.13.4-051304.202107201535_amd64.deb
linux-headers-5.13.4-051304_5.13.4-051304.202107201535_all.deb
```

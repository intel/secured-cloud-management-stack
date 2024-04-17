# Build openEuler 22.03 LTS TDX MVP Stack
User can follow the document to build the TDX MVP Host and Guest Repositoty on OS: openEuler 22.03 LTS.

**Table of contents**

- [Build openEuler 22.03 LTS TDX MVP Stack](#build-openeuler-2203-lts-tdx-mvp-stack)
  - [Require,emys](#requirements)
  - [Build host kernl packages](#build-host-kernl-packages)
  - [Reference](#reference)


## Requirements
1. Disk space > 60GB.
2. Intall dependencies.
```
curl -o /etc/yum.repos.d/epel-OpenEuler.repo https://down.whsir.com/downloads/epel-OpenEuler.repo
dnf install -y git createrepo tar
```

3. Download tdx-tools WW15 Package
```
git clone https://github.com/intel/tdx-tools.git
cd tdx-tools/
git checkout 2023ww15
```

4. (Optional)Download dcap package and extract sgx_source.tar.gz
```
tar xf dcap-20230406.tar.gz
cp dcap-20230406/sgx_source.tar.gz  tdx-tools/build/common/tdx-migration-src/
```

## Build host kernl packages
The `buid-repo.sh` scipt builds host packages into host_repo/ .
```
cd build/rhel-8

# comment the unbuild lines
sed -i '14,16s/^/#/' build-repo.sh
sed -i '65,68s/^/#/' build-repo.sh
sed -i '81s/^/#/' build-repo.sh
sed -i '84s/^/#/' build-repo.sh
sed -i '88s/^/#/' build-repo.sh

# Replace dependency
sed  -i 's/redhat-rpm-config/openEuler-rpm-config/g' intel-mvp-tdx-kernel/tdx-kernel.spec

./build-repo.sh
```
The build repo structure as below:
```
repo/
└── host
    ├── noarch
    ├── repodata
    ├── src
    └── x86_64
```

## Install tdx kernel from source code
1. Download kernel source code and comment rpmbuild steps
```
cd build/rhel-8/intel-mvp-tdx-kernel
sed -i '55s/^/#/' build.sh
./build.sh
```
2. Build tdx kernel
```
cd linux-tdx-kernel/
make mrproper
make clean

# copy the tdx kernel config and load it
cp ../tdx-base.config .config
make menuconfig               

make -j $(nproc)
make modules_install
make install
```

3. Change grub menu
```
sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 numa_balancing=disable"/' /etc/default/grub
grub2-mkconfig -o /boot/efi/EFI/openEuler/grub.cfg 
```

4. Chose the default kernel
```
grubby --set-default /boot/vmlinuz-<the build version>
```

5. Reboot and change the BIOS to enable tdx

6. Login the OS to check tdx module load information
```
sudo dmesg | grep tdx
```

## Reference
[RHEL 8 TDX MVP Stack](https://github.com/intel/tdx-tools/blob/2023ww15/build/rhel-8/README.md)
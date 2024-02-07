# Build Ubuntu 22.04 TDX MVP Stack
User can follow the document to build the TDX MVP Host and Guest Repositoty on OS: Ubuntu 22.04.

**Table of contents**

- [Build Ubuntu 22.04 TDX MVP Stack](#build-ubuntu-2204-tdx-mvp-stack)
  - [Requirements](#requirements)
  - [Buid guest repo](#build-guest-repo)
  - [Reference](#reference)


## Requirements
1. Disk space > 60GB.
2. Intall dependencies.
```
apt install --no-install-recommends --yes build-essential fakeroot \
        devscripts wget git equivs liblz4-tool sudo python-is-python3 \   
        python3-dev pkg-config unzip
```
3. Create a sudo user with passwordless
```
useradd tdx
echo "tdx ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tdx
```
4. Download tdx-tools WW15 Package
```
su tdx
git clone https://github.com/intel/tdx-tools.git
cd tdx-tools/
git checkout 2023ww15
```

## Build guest repo
The `buid-repo.sh` scipt builds host packages into `host_repo/` and guest packages into `guest_repo/`, but we only need to build guest repo.
Comment the following functions in tdx-tools/build/ubuntu-22.04/build-repo.sh
```
#build_qemu
#build_tdvf
#build_libvirt
```

Then build guest repo
```
cd tdx-tools/build/ubuntu-22.04
./build-repo.sh
```

## Reference
[Ubuntu22.04 TDX MVP Stack](https://github.com/intel/tdx-tools/blob/2023ww15/build/ubuntu-22.04/README.md)
# Build RHEL 8 TDX MVP Stack
User can follow the document to build the TDX MVP Host and Guest Repositoty on OS: RHEL 8.

**Table of contents**

- [Build RHEL 8 TDX MVP Stack](#build-rhel-8-tdx-mvp-stack)
  - [Requirements](#requirements)
  - [Buid all](#build-both-host-and-guest-repos)
  - [Reference](#reference)


## Requirements
1. Disk space > 60GB.
2. Intall dependencies.
```
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y git createrepo tar
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

## Build both host and guest repos
The `buid-repo.sh` scipt builds host packages into `repo/host/` and guest packages into `repo/guest/`.
```
cd tdx-tools/build/rhel-8
./build-repo.sh
```

## Reference
[RHEL 8 TDX MVP Stack](https://github.com/intel/tdx-tools/blob/2023ww15/build/rhel-8/README.md)
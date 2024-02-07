# SCM V2.0

## Pre-request
- **Server**: Intel 3rd or later Generation Platform or SGX VM.
- **BIOS**: Enable SGX, operations refer to [SGX BIOS Configuration](../scm1.0/doc/user-guide/bios_config.md).
- **OS**: CentOS8.4/Redhat8.4/Ubuntu20.04/openEuler22.03 with UEFI bot.
- **Hardware**: >2 cores; >2GB memory.
- **Time**: Time zone is consistent with time.

## Build depenencies
```
cd ~/scm2.0/roles/sgx-k8s/files/
docker build -f mpa.Dockerfile -t mpa:v1.15 --build-arg http_proxy=<your proxy> --build-arg https_proxy=<your
proxy> .
docker build -f pccs.Dockerfile -t pccs:v1.15 --build-arg http_proxy=<your proxy> --build-arg https_proxy=<your
proxy> .
docker build -f aesmd.Dockerfile -t aesmd:v2.18 --build-arg http_proxy=<your proxy> --build-arg https_proxy=<your
proxy> .
docker build -f dcap-sample.Dockerfile -t dcap-sample:v1.15 --build-arg http_proxy=<your proxy> --build-arg
https_proxy=<your proxy> .
docker save mpa:v1.15 -o mpa.tar
docker save pccs:v1.15 -o pccs.tar
docker save aesmd:v2.18 -o aesmd.tar
docker save dcap-sample:v1.15 -o dcap-sample.tar

```

## Configuration

1. Move the map.tar, pccs.tar, aesmd.tar and dcap-sample.tar packages to ~/scm2.0/roles/sgx-k8s/file.

2. Set your API_KEY in [main.yaml](./roles/sgx-k8s/defaults/main.yml), you can register your key from [provisioning certification](https://api.portal.trustedservices.intel.com/provisioning-certification).
```
pccs_api_key: "<your_api_key>
```

3. If you deploy the K8s stack in SGX VM, please disbale MP register service in [main.yaml](./roles/sgx-k8s/defaults/main.yml).
```
enable_mpa: false
```

4. Change Ip in the [hosts](./inventory/hosts) file accroding to your cluster configuration
```
[deployment_host] #Deployment node, set as localhost
localhost
[kubernetes_hosts] #All Kubernetes nodes ip
172.31.100.101
172.31.100.102
172.31.100.103
[kubernetes_master_hosts] #All Kubernetes master nodes ip
172.31.100.101
[kubernetes_worker_hosts] #All Kubernetes worker nodes ip
172.31.100.101
172.31.100.102
172.31.100.103
[sgx_hosts] #All SGX nodes ip
172.31.100.101
172.31.100.102
172.31.100.103
```

5. Keep all the nodes with same user name and set passward free for all the hosts.
```
ssh-copy-id <user>@localhost
ssh-copy-id <user>@ip
```

6. Proxy configuration in [all.yaml](./inventory/group_vars/all.yml)
```
---
http_proxy: <your_proxy>
https_proxy: <your_proxy>
```

## Deployment Kubernetes 
Note: By default, our script deploy kubernetes v1.23.10 with container runtime containerd. Others, you can deploy manually.
```
cd ~
python3 -m venv venv
source ~/venv/bin/activate

pip install -U pip
pip install -r ~/scm2.0/requirements_pip.txt
cd ~/scm2.0
ansible-playbook -i inventory/hosts k8s.yaml
```

## Deploy SGX Related Services
```
ansible-playbook -i inventory/hosts sgx.yml

```

## Demo Case: Test SGX Quote Generation
```
# Load dcap-sample image
ctr -n k8s.io image dcap-sample.tar

# Run dcap test pod 
cd ~/scm2.0/roles/sgx-k8s/files
kubectl apply -f dcap-sample.yaml

# Check the output
kubectl logs -f dcap-sample

output:
Step1: Call sgx_qe_get_target_info:succeed!
Step2: Call create_app_report:succeed!
Step3: Call sgx_qe_get_quote_size:succeed!
Step4: Call sgx_qe_get_quote:succeed!cert_key_type = 0x5

```

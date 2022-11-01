# Create SGX-enabled Instances

Creating SGX-enabled instance requires SGX-enabled flavor and image.
SGX-enabled flavor has `resources:CUSTOM_SGX_EPC_MB=xxx` and
`trait:HW_CPU_X86_SGX=requried` in its extra specs. The value of `xxx`
represents the memory size of EPC that guest needs, which is greater than 0 and
less than the SGX-capable host's supply. SGX-enabled image has the property
of `trait:HW_CPU_X86_SGX=required`.

**All bash scripts in below sections are executed on Bare1's Operating System (OS).
User should SSH to 172.16.150.101 to execute them.**

## Prepare for creation

1. Initial Environment

    ```bash
    source ~/src/kayobe-config/etc/kolla/admin-openrc.sh
    source ~/venvs/kolla-ansible/bin/activate
    ```

2. Create Network

    ```bash
    openstack network create --provider-physical-network physnet1 --provider-network-type vlan  --provider-segment 143 --share --enable-port-security provision-net
    openstack subnet create --subnet-range 172.16.143.0/24 --allocation-pool start=172.16.143.221,end=172.16.143.230 --network provision-net provision-net-sub
    ```

3. Create KeyPair

    ```bash
    openstack keypair create --public-key .ssh/id_rsa.pub cloud-key 
    ```

4. Set quota of SGX EPC

   Please refer [updating quota for SGX EPC](./client_quota.md). 

## Complete Creation of Virtual Instance

1. Create Flavor

    ```bash
    openstack flavor create --ram 4096 --vcpus 2 --disk 20 \
    --property resources:CUSTOM_SGX_EPC_MB=3 \
    --property trait:HW_CPU_X86_SGX='required' sgx-2c-4g
    ```

    *SGX-enabled VM flavor needs to specify properties of resource:CUSTOM_SGX_EPC_MB and trait:HW_CPU_X86_SGX.*


2. Upload Image

    ```bash
    openstack image create --file <file path of SGX-enabled vm image> --disk-format qcow2 \
    --container-format bare --property usage_type='common' \
    --property os_distro=others --property hw_qemu_guest_agent=no \
    --property os_admin_user=root \
    --property trait:HW_CPU_X86_SGX='required' \
    --public sgx-vm-image
    ```
   
    *SGX-enabled VM image needs to specify property of trait:HW_CPU_X86_SGX.
     Please build SGX-enabled VM image first.*

3. Create Server

    ```bash
    openstack server create --flavor sgx-2c-4g --network provision-net \
    --image sgx-vm-image  --key-name cloud-key sgx-virtual-instance
    ```

## Complete Creation of Bare metal Instance

1. Create Flavor

    ```bash
    openstack flavor create --ram 262144 --vcpus 128 --disk 2048 \
    --property resources:CUSTOM_SGX_EPC_MB=0 \
    --property trait:HW_CPU_X86_SGX='required' \
    --property resources:CUSTOM_SGX_BAREMETAL=1 \
    --property resources:VCPU=0 \
    --property resources:MEMORY_MB=0 \
    --property resources:DISK_GB=0 sgx-baremetal-128c-256g
    ```

    *SGX-enabled bare metal flavor needs to specify properties of resource:CUSTOM_SGX_EPC_MB, 
     trait:HW_CPU_X86_SGX and resources:CUSTOM_SGX_BAREMETAL*

2. Create Image

    ```bash
    openstack image create --file <file path of SGX-enabled bare metal image> --disk-format qcow2 \
    --container-format bare --property usage_type='common' \
    --property os_distro=others --property hw_qemu_guest_agent=no \
    --property os_admin_user=root \
    --property trait:HW_CPU_X86_SGX='required' \
    --public sgx-bare-metal-image
    ```

    *SGX-enabled bare metal image needs to specify property of trait:HW_CPU_X86_SGX.
     Please build SGX-enabled bare metal image first.*

3. Create Server

    ```bash
    openstack server create --flavor sgx-baremetal-128c-256g \
    --network provision-net \
    --image  sgx-bare-metal-image \
    --key-name cloud-key sgx-bare-metal-instance
    ```

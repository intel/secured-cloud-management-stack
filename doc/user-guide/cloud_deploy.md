# Deploy SGX-enabled Cloud

[Kayobe](https://docs.openstack.org/kayobe/latest/) is used to deploy the OpenStack cloud platform.
It uses Bifrost, Kolla-ansible, Ironic, .etc to complete the deployment.
In the concept of Kayobe, hosts can be mainly divided into [five categories](https://docs.openstack.org/kayobe/latest/architecture.html).

- Ansible Control Host (ACH)

  The ACH is the host on which kayobe, Kolla and Kolla-ansible will be installed,
  and is typically where the cloud will be managed from.


- Seed Host (SH)

  The SH runs the Bifrost deploy container and is used to provision the cloud hosts.
  By default, container images are built on the SH.
  Typically the SH is deployed as a VM but this is not mandatory.


- Cloud Hosts (CHs)

  The Cloud hosts run the OpenStack control plane, network, monitoring, storage,
  and virtualised compute services. Typically the Cloud hosts run on bare metal but this is not mandatory.


- Infrastructure VM Hosts (IVHs)

  IVHs are virtual machines that may be deployed to
  provide supplementary infrastructure services.
  They may be for things like proxies or DNS servers that are dependencies of the CHs.


- Bare Metal Compute Hosts (BMCHs)

  In a cloud providing bare metal compute services to tenants via Ironic,
  these hosts will run the bare metal tenant workloads.
  In a cloud with only virtualised compute this category of hosts does not exist.

This section provides operations of deploying a simple SGX-enabled cloud.
For complex scenes, please refer to [Kyaobe Document](https://docs.openstack.org/kayobe/latest/).
The simple SGX-enabled cloud is built on four bare metals.
ACH and SH share a bare metal.
CH uses two bare metas, and BMCH use one bare meta.
There is no IVHs in this sample.
The architecture diagram is shown below.
From left to right, Bare1, Bare, Bare3 and Bare4 are the names of these bare metas.

```text
                             +---------------------------+-------------------------------+----------------------------------------------+----------------+ external 172.16.143.0/24
                                                         |                               |                                              |
                                                         |                               |                                              |
                                                         |                               |                                              |
                      +--------------------------+--------------------------------+------------------------------------+------------------------------+ provider 172.16.142.0/24
                                                 |       |                        |      |                             |                |
                                         172.16.142.202  |                172.16.142.203 |                             |                |
                                                 |       |                        |      |                             |                |
          +------------------------------+---------------------------------+------------------------------------------------------------------------+ cloud  172.16.141.0/24
                                         |       |       |                 |      |      |                             |                |
                                 172.16.141.202  |       |         172.16.141.203 |      |                             |                |
                                         |       |       |                 |      |      |                             |                |
 +------+------------------------------------------------------+-------------------------------------+-------------------------------------------+ management 172.16.150.0/24
        |                                |       |       |     |           |      |      |           |                 |                |
        |                                |       |       |     |           |      |      |           |                 |                |
        |                                |       |       |     |           |      |      |           |                 |                |
        |                                +-------+-------+     |           +------+------+           |                 +-------+--------+
        |                                        |             |                  |                  |                         |
        |                                        |             |                  |                  |                         |
        |                                        |             |                  |                  |                         |
 172.16.150.101                                  |      172.16.150.102            |           172.16.150.103                   |
        |                                        |             |                  |                  |                         |
    +---+----------------------+    +------------+-------------+---+       +------+------------------+----+       +------------+---------------+
    |  eth0                    |    |           eth2         eth1  |       |     eth3               eth1  |       |           eth0             |
    |                          |    |                              |       |                              |       |                            |
    |                          |    | eth2.141 eth2.142 breth2     |       | eth3.141 eth3.142 breth3     |       |                            |
    |                          |    |                              |       |                              |       |                            |
    |                          |    |                              |       |                              |       |                            |
    |         ACH / SH         |    |             CH               |       |            CH                |       |           BMCH             |
    |                          |    |                              |       |                              |       |                            |
    |         Bare1            |    |            Bare2             |       |           Bare3              |       |           Bare4            |
    |                          |    |                              |       |                              |       |                            |
    |                          |    |                              |       |                              |       |                            |
    |                          |    |                              |       |                              |       |                            |
    |         bmc              |    |             bmc              |       |             bmc              |       |           bmc              |
    +----------+---------------+    +--------------+---------------+       +--------------+---------------+       +------------+---------------+
               |                                   |                                      |                                    |
        172.16.140.201                     172.16.140.202                          172.16.140.203                       172.16.140.204
               |                                   |                                      |                                    |
+--------------+-----------------------------------+--------------------------------------+------------------------------------+-----------+ ipmi  172.16.140.0/24
```

**All bash scripts in below sections are executed on Bare1's Operating System (OS).
User should SSH to 172.16.150.101 to execute them.**

## Bare1

### Install OS

*The OS of Bare1 needs to be installed manually.
Please refer to web materials.
The OS installed in sample is Centos 8.4, and commands are executed by default user `centos`.*

### Initial Environment

1. Disable Syslinux

    ```bash
    sudo setenforce 0
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    ```

2. Replace YUM Repo

    ```bash
    sudo rm -rf /etc/yum.repos.d/*
    cat <<EOF | sudo tee -a /etc/yum.repos.d/CentOS-Base.repo
    [base]
    name=CentOS-8.5.2111 - Base - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/\$basearch/os/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/BaseOS/\$basearch/os/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/BaseOS/\$basearch/os/
    gpgcheck=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official

    #additional packages that may be useful
    [extras]
    name=CentOS-8.5.2111 - Extras - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/extras/\$basearch/os/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/extras/\$basearch/os/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/extras/\$basearch/os/
    gpgcheck=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official

    #additional packages that extend functionality of existing packages
    [centosplus]
    name=CentOS-8.5.2111 - Plus - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/centosplus/\$basearch/os/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/centosplus/\$basearch/os/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/centosplus/\$basearch/os/
    gpgcheck=0
    enabled=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official

    [PowerTools]
    name=CentOS-8.5.2111 - PowerTools - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/PowerTools/\$basearch/os/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/PowerTools/\$basearch/os/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/PowerTools/\$basearch/os/
    gpgcheck=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official


    [AppStream]
    name=CentOS-8.5.2111 - AppStream - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/AppStream/\$basearch/os/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/AppStream/\$basearch/os/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/AppStream/\$basearch/os/
    gpgcheck=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official

    [Cloud]
    name=CentOS-8.5.2111 - Cloud - mirrors.aliyun.com
    baseurl=http://mirrors.aliyun.com/centos-vault/8.5.2111/cloud/\$basearch/openstack-train/
            http://mirrors.aliyuncs.com/centos-vault/8.5.2111/cloud/\$basearch/openstack-train/
            http://mirrors.cloud.aliyuncs.com/centos-vault/8.5.2111/cloud/\$basearch/openstack-train/
    gpgcheck=0
    gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official
    EOF
    sudo yum install -y epel-release.noarch
    ```

    *Centos's repo used in this sample is provided by Aliyun. It can be replaced by others.*


3. (optional) Configure HTTP/HTTPS Proxy

    ```bash
    echo "export http_proxy=<proxy server>" >> ~/.bashrc
    echo "export https_proxy=<proxy server>" >> ~/.bashrc
    echo "export no_proxy=127.0.0.1,localhost,172.16.150.101"  >> ~/.bashrc
    source ~/.bashrc
    ```

4. Install Required Packages

    ```bash
    sudo yum install -y platform-python-devel gcc libffi-devel git virtualenv python3-pip epel-release.noarch
    ```

### Install Kayobe

1. Initial Python Virtual Environment

    ```bash
    cd ~
    sudo alternatives --set python /usr/bin/python3
    mkdir -p src venvs
    python -m venv --system-site-packages venvs/kayobe
    source ~/venvs/kayobe/bin/activate
    sudo pip3 install -U pip
    sudo pip3 install -U setuptools
    ```

2. Install from Source Code

    ```bash
    cd ~/src
    git clone -b stable/train https://opendev.org/openstack/kayobe.git
    echo '  become: true' >> kayobe/ansible/roles/docker-registry/tasks/deploy.yml
    echo '---' > kayobe/ansible/roles/image-download/tasks/main.yml
    sed -i 's/^kolla_overcloud_inventory_pass_through_host_vars:/kolla_overcloud_inventory_pass_through_host_vars:\n  - "enable_sgx"\n  - "enable_dcap"/g' ~/src/kayobe/ansible/group_vars/all/kolla
    sed -i 's/^kolla_overcloud_inventory_pass_through_host_vars_map:/kolla_overcloud_inventory_pass_through_host_vars_map:\n  enable_sgx: "enable_sgx"\n  enable_dcap: "enable_dcap"/g' ~/src/kayobe/ansible/group_vars/all/kolla
    pip install ./kayobe
    git clone -b stable/train https://opendev.org/openstack/kayobe-config.git
    cd ~
    source ~/src/kayobe-config/kayobe-env
    ```

### Configure Bare1 as ACH

```bash
kayobe control host bootstrap
```

### Custom Kolla-Ansible to support deploy SGX PSW containers

1. Apply patch of Kolla-Ansible

    ```bash
    cd ~
    git clone git@github.com:intel-collab/applications.services.cloud.confidential-computing.sgx-hmc-solution.git
    cd ~/src/kolla-ansible
    git checkout -b train-9.3.2 tags/9.3.2
    git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/kolla-ansible-intel-sgx.patch
    ```

2. Set `kolla_ansible_source_version` in `~/src/kayobe-config/etc/kayobe/kolla.yml`

    ```yaml
    kolla_ansible_source_version: train-9.3.2
    ```

3. Set Following Options in `~/src/kayobe-config/etc/kayobe/kolla/globals.yml`

    ```yaml
    dcap_api_key: <api key of intel>
    dcap_user_password_hash: <sha512 of custom password of user>
    dcap_admin_password_hash: <sha512 of custom password of admin>
    ```

4. Reconfigure Bare1

    ```bash
    cd ~
    kayobe control host bootstrap
    ```

### Configure Bare1 as SH

1. Set `~/src/kayobe-config/etc/kayobe/networks.yml` as Follows

    ```yaml
    ---
    admin_oc_net_name: management
    oob_oc_net_name: management
    provision_oc_net_name: management
    oob_wl_net_name: management
    provision_wl_net_name: external
    internal_net_name: cloud
    external_net_names:
      - external
    public_net_name: cloud
    tunnel_net_name: cloud
    storage_net_name: cloud
    storage_mgmt_net_name: cloud
    inspection_net_name: provider
    cleaning_net_name: external

    # management network definition.
    management_cidr: 172.16.150.0/24
    management_allocation_pool_start: 172.16.150.101
    management_allocation_pool_end: 172.16.150.110
    management_inspection_allocation_pool_start: 172.16.150.111
    management_inspection_allocation_pool_end: 172.16.150.120
    management_routes:
      - cidr: 0.0.0.0/0
        gateway: 172.16.150.1
      - cidr: 172.16.150.0/24
        gateway: 172.16.150.1

    # cloud network definition.
    cloud_cidr: 172.16.141.0/24
    cloud_vlan: 141
    cloud_allocation_pool_start: 172.16.141.201
    cloud_allocation_pool_end: 172.16.141.210
    cloud_rules:
      - from 172.16.141.0/24 table cloudroutetable
    cloud_routes:
      - cidr: 0.0.0.0/0
        gateway: 172.16.141.1
        table: cloudroutetable
      - cidr: 172.16.141.0/24
        gateway: 172.16.141.1

    # provider network definition
    provider_cidr: 172.16.142.0/24
    provider_vlan: 142
    provider_allocation_pool_start: 172.16.142.201
    provider_allocation_pool_end: 172.16.142.210
    provider_inspection_allocation_pool_start: 172.16.142.211
    provider_inspection_allocation_pool_end: 172.16.142.220
    provider_rules:
      - from 172.16.142.0/24 table providerroutetable
    provider_routes:
      - cidr: 0.0.0.0/0
        gateway: 172.16.142.1
        table: providerroutetable
      - cidr: 172.16.142.0/24
        gateway: 172.16.142.1

    # external network definition.
    external_vlan: 143

    network_route_tables:
      - name: cloudroutetable
        id: 200
      - name: providerroutetable
        id: 201

    workaround_ansible_issue_8743: yes
    ```

2. Set `~/src/kayobe-config/etc/kayobe/network-allocation.yml` as Follows

    ```yaml
    ---
    management_ips:
      localhost: 172.16.150.101
      controller01: 172.16.150.102
      compute01: 172.16.150.103
    cloud_ips:
      controller01: 172.16.141.202
      compute01: 172.16.141.203
    provider_ips:
      controller01: 172.16.142.202
      compute01: 172.16.142.203
    ```

3. Rename `hosts.example` in `~/src/kayobe-config/etc/kayobe/inventory/` to `hosts`, and Set as Follows

    ```ini
    localhost ansible_connection=local ansible_user=centos ansible_python_interpreter=/home/centos/venvs/kayobe/bin/python

    [seed-hypervisor]

    [seed]
    localhost

    [controllers]

    [baremetal-compute]

    [mgmt-switches]

    [ctl-switches]

    [hs-switches]
    ```

4. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/seed/network-interfaces` as Follows

    ```yaml
    ---
    management_interface: eth0
    workaround_ansible_issue_8743: yes
    ```

5. Set `seed_lvm_group_data_disks` in `~/src/kayobe-config/etc/kayobe/seed.yml`

    ```yaml
    seed_lvm_group_data_disks:
      - /dev/vdb
    ```

    *This sample use /dev/vdb to provide storage to Docker.
     Other disk device is OK, but the disk device should be unmounted, and over 300 GB.*


6. Set `kayobe_ansible_user` Option in `~/src/kayobe-config/etc/kayobe/globals.yml`

    ```yaml
    kayobe_ansible_user: centos
    ```

7. Configure SSH Password-free Login

    ```bash
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys
    ```

8. Set `docker_registry_enabled` in `~/src/kayobe-config/etc/kayobe/docker-registry.yml`

    ```yaml
    docker_registry_enabled: true
    ```

9. Set `kolla_docker_registry` in `~/src/kayobe-config/etc/kayobe/kolla.yml`

    ```yaml
    kolla_docker_registry: 172.16.150.101:4000
    ```

10. Initial Host

    ```bash
    kayobe seed host configure
    sudo usermod -aG docker centos
    newgrp docker
    ```

11. Set `kolla_bifrost_inspector_ipmi_username` and `kolla_bifrost_inspector_ipmi_password` in `~/src/kayobe-config/etc/kayobe/bifrost.yml`

    ```yaml
    kolla_bifrost_inspector_ipmi_username="<ipmi username of bare metals acting as CHs>"
    kolla_bifrost_inspector_ipmi_password="<ipmi password of bare metals acting as CHs>"
    ```

    *In order to use inspector, all bare metals should have the same ipmi username and ipmi password.*


12. Set `openstack_tag_suffix` in `~/src/kayobe-config/etc/kayobe/kolla/globals.yml`

    ```yaml
    openstack_tag_suffix: "-centos8s"
    ```

13. Build SGX-enabled Docker Images first, then upload them to registry Container

    ```bash
    scp <file path of openstack-train-intel-sgx.tar> ~/
    sudo docker load -i openstack-train-intel-sgx.tar
    sudo docker image ls --format '{{.Repository}}' | grep '^kolla' | xargs -I {} sudo docker tag {}:train-centos8s 172.16.150.101:4000/{}:train-centos8s
    sudo docker image ls --format '{{.Repository}}' | grep '^kolla' | xargs -I {} sudo docker push 172.16.150.101:4000/{}:train-centos8s
    sudo docker image ls --format '{{.Repository}}' | grep '^custom' | xargs -I {} sudo docker tag {}:latest 172.16.150.101:4000/{}:latest
    sudo docker image ls --format '{{.Repository}}' | grep '^custom' | xargs -I {} sudo docker push 172.16.150.101:4000/{}:latest
    ```

14. (optional) Set `container_http_proxy` and `container_https_proxy` in `/home/centos/src/kayobe-config/etc/kayobe/kolla/globals.yml`

    ```yaml
    container_http_proxy: "<proxy server>"
    container_https_proxy: "<proxy server>"
    container_no_proxy: "localhost,127.0.0.1,172.16.150.101"
    ```

15. Build SGX-enabled Host Image and IPA Image first, then upload them to the container of bifrost_deploy

    ```yaml
    sudo docker volume create bifrost_httpboot
    sudo cp <host image path>  /var/lib/docker/volumes/bifrost_httpboot/_data/deployment_image.qcow2
    sudo cp <ipa kernel path> /var/lib/docker/volumes/bifrost_httpboot/_data/ipa.vmlinuz
    sudo cp <ipa initramfs path> /var/lib/docker/volumes/bifrost_httpboot/_data/ipa.initramfs
    ```

16. Bootstrap bifrost_deploy container and start Ironic Services

    ```bash
    kayobe seed service deploy
    ```

### Custom Ironic-Inspector to support detect SGX properties

1. Apply patch of Ironic-Inspector

    ```bash
    cd ~
    docker cp ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/ironic-inspector-intel-sgx.patch bifrost_deploy:/root/
    docker exec -it -uroot bifrost_deploy /bin/bash
    cd /opt/stack/ironic-inspector/
    git am ~/ironic-inspector-intel-sgx.patch
    source /var/lib/kolla/venv/bin/activate
    pip install ./
    sed -i '/^processing_hooks.*$/s/$/,sgx/g' /etc/ironic-inspector/inspector.conf
    exit
    ```

2. Restart bifrost_deploy

    ```bash
    docker restart bifrost_deploy
    ```

## Bare2 and Bare3

### Enable SGX in BIOS

### Install OS

Unlike Bare1, the installation of Bare2's and Bare3's OS is automated,
which is based on PXE technology and OpenStack Ironic installed in Bare1.

1. Power on Bare2 and Bare3

2. Check Whether Bare2 and Bare3 are introspected by Ironic (this may take several minutes)

    ```bash
    sudo docker exec -it bifrost_deploy bash
    export OS_CLOUD=bifrost
    openstack baremetal node list
    openstack baremetal node set <UUID of Bare2> --name controller01
    openstack baremetal node set <UUID of Bare3> --name compute01
    exit
    ```

3. (optional) Clean Bare2's and Bare3's disks

    ```bash
    sudo docker exec -it bifrost_deploy bash
    export OS_CLOUD=bifrost
    openstack baremetal node list
    openstack baremetal node manage <UUID of Bare2>
    openstack baremetal node clean <UUID of Bare2> --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
    openstack baremetal node manage <UUID of Bare3>
    openstack baremetal node clean <UUID of Bare3> --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
    exit
    ```

4. Group Bare2 and Bare3

    Kayobe provides four overcloud groups by default, which are `controllers`, `compute`, `monitoring` and `storage`.
    It is possible to create other groups, but custom groups should be children of default groups.
    The following steps will create two new groups: `controller-1` and `compute-1`.
    `controllers-1` is the children of `controllers`.
    `compute-1` is the children of `compute`.

    1. Set `~/src/kayobe-config/etc/kayobe/inventory/groups` as follows

        ```yaml
        [seed]

        [seed-hypervisor]

        [container-image-builders:children]
        seed

        [controllers-1]

        [compute-1]

        [controllers:children]
        controllers-1

        [network:children]
        controllers-1

        [compute:children]
        compute-1

        [monitoring]

        [storage]

        [overcloud:children]
        controllers
        network
        monitoring
        storage
        compute

        [docker:children]
        seed
        controllers
        network
        monitoring
        storage
        compute

        [docker-registry:children]
        seed

        [baremetal-compute]

        [mgmt-switches]

        [ctl-switches]

        [hs-switches]

        [switches:children]
        mgmt-switches
        ctl-switches
        hs-switches
        ```

    2. Create variable folders for custom groups

        ```bash
        mkdir -p ~/src/kayobe-config/etc/kayobe/inventory/group_vars/controllers-1
        mkdir -p ~/src/kayobe-config/etc/kayobe/inventory/group_vars/compute-1
        ```

    3. Set `overcloud_group_hosts_map` in `~/src/kayobe-config/etc/kayobe/overcloud.yml`

        ```yaml
        overcloud_group_hosts_map:
          controllers-1:
            - controller01
          compute-1:
            - compute01
        ```

5. Generate overcloud inventory from inspected bare metal nodes

    ```bash
    kayobe playbook run venvs/kayobe/share/kayobe/ansible/overcloud-inventory-discover.yml
    ```

6. Write OS to Bare2's and Bare3's Disk

    ```bash
    kayobe overcloud provision
    ```

### Deploy Overcloud

1. Set Following Options in `~/src/kayobe-config/etc/kayobe/kolla.yml`

    ```yaml
    kolla_enable_haproxy: false
    kolla_enable_ironic_ipxe: "yes"
    kolla_enable_ironic_pxe_uefi: "yes"
    kolla_install_type: "source"
    kolla_neutron_bridge_names: "br-ex"
    kolla_enable_neutron_provider_networks: "yes"
    ```

    *The sample is deployed in single-control mode. In multi-controls mode, `enable_haproxy` should be set to `true`,
     and `cloud_vip_address: <cloud virtual ip>` should be added to `~/src/kayobe-config/etc/kayobe/networks.yml`.*

2. Set `distro_python_version` in `~/src/kayobe-config/etc/kayobe/kolla/globals.yml`

    ```yaml
    distro_python_version: "3.6"
    ```

3. Set pip options in `~/src/kayobe-config/etc/kayobe/pip.yml`
    ```yaml
    pip_upper_constraints_file: "https://opendev.org/openstack/requirements/raw/branch/stable/train/upper-constraints.txt"
    pip_local_mirror: true
    pip_index_url: "https://pypi.org/simple/"
    pip_trusted_hosts: ['opendev.org']
    ```

4. set `kolla_overcloud_inventory_top_level_group_map` in `~/src/kayobe-config/etc/kayobe/kolla.yml`

    ```yaml
    kolla_overcloud_inventory_top_level_group_map:
      control:
        groups:
          - controllers-1
      compute:
        groups:
          - compute-1
      network:
        groups:
          - controllers-1
    ```

5. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/controllers-1/network-interfaces` as follows

    ```yaml
    management_interface: eth1
    cloud_interface: "eth2.{{ cloud_vlan }}"
    provider_interface: "eth2.{{ provider_vlan }}"
    external_interface: "breth2"
    external_bridge_ports:
      - eth2
    workaround_ansible_issue_8743: yes
    ```

6. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/compute-1/network-interfaces` as follows

    ```yaml
    management_interface: eth1
    cloud_interface: "eth3.{{ cloud_vlan }}"
    provider_interface: "eth3.{{ provider_vlan }}"
    external_interface: "breth3"
    external_bridge_ports:
      - eth3
    workaround_ansible_issue_8743: yes
    ```

7. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/controllers-1/sgx` as follows

    ```yaml
    enable_dcap: true
    ```

8. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/compute-1/sgx` as follows

   ```yaml
   enable_sgx: true
   ```

9. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/controllers-1/lvm` as follows

    ```yaml
    controller_lvm_group_data_disks:
      - /dev/vdb
    ```

    *This sample use /dev/vdb to provide storage to Docker.
     Other disk device is OK, but the disk device should be unmounted, and over 300 GB.*

10. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/compute-1/lvm` as follows

    ```yaml
    compute_lvm_group_data_disks:
      - /dev/vdb
    ```

    *This sample use /dev/vdb to provide storage to Docker.
     Other disk device is OK, but the disk device should be unmounted, and over 300 GB.*

11. Set `~/src/kayobe-config/etc/kayobe/inventory/group_vars/controllers-1/sysctl` as follows

    ```yaml
    controller_sysctl_parameters:
       net.ipv4.ip_forward: 1
       net.ipv4.conf.all.rp_filter: 0
       net.ipv4.conf.eth2/141.rp_filter: 0
       net.ipv4.conf.eth2/142.rp_filter: 0
    ```

12. Generate Inventory of Kolla-ansible by Kayobe settings

    ```bash
    kayobe overcloud inventory discover
    ```

13. Initial Environment

    ```bash
    kayobe overcloud host configure  --wipe-disks
    ```

14. Configure OpenStack Services

    ```bash
    mkdir -p ~/src/kayobe-config/etc/kayobe/kolla/config
    cat << EOF > ~/src/kayobe-config/etc/kayobe/kolla/config/nova.conf
    [DEFAULT]
    force_config_drive = True

    [libvirt]
    sgx_epc_mb = 61440
    cpu_mode = host-passthrough
    EOF

    cat << EOF > ~/venvs/kolla-ansible/share/kolla-ansible/ansible/roles/nova-cell/templates/qemu.conf.j2
    stdio_handler = "file"

    user = "root"
    group = "root"

    max_files =  {{ qemu_max_files }}
    max_processes =  {{ qemu_max_processes }}

    cgroup_device_acl = [
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm",
        "/dev/rtc","/dev/hpet",
        "/dev/sgx_enclave", "/dev/sgx_provision", "/dev/sgx_vepc"
    ]
    EOF

    cat << EOF > ~/src/kayobe-config/etc/kayobe/kolla/config/ironic-inspector.conf
    [processing]
    processing_hooks = ramdisk_error,scheduler,validate_interfaces,capabilities,pci_devices,local_link_connection,lldp_basic,sgx
    store_data = database
    EOF

    cat << EOF > ~/src/kayobe-config/etc/kayobe/kolla/config/ironic.conf
    [conductor]
    automated_clean = true
    EOF
    ```

15. （optional）Configure `sgx_epc_mb` for `compute01` in `compute-1`

    ```bash
    mkdir -p ~/src/kayobe-config/etc/kayobe/kolla/config/nova/compute01
    cat <<EOF > ~/src/kayobe-config/etc/kayobe/kolla/config/nova/compute01/nova.conf
    [libvirt]
    sgx_epc_mb = 30720
    EOF
    ```

16. Build SGX-enabled IPA Image first, then upload them to `~/src/kayobe-config/etc/kayobe/kolla/config/ironic/`

    ```bash
    mkdir -p ~/src/kayobe-config/etc/kolla/config/ironic
    cp <ipa kernel path> ~/src/kayobe-config/etc/kolla/config/ironic/ironic-agent.kernel
    cp <ipa initramfs path> ~/src/kayobe-config/etc/kolla/config/ironic/ironic-agent.initramfs
    ```

17. Bootstrap OpenStack Components

    ```bash
    kayobe overcloud service deploy
    ```

## Bare4

### Enable SGX in BIOS

### Register Bare4 to Overcloud

1. Create Ironic Introspection Rules in Overcloud

    ```bash
    source venvs/kolla-ansible/bin/activate
    source src/kayobe-config/etc/kolla/admin-openrc.sh

    cd ~
    git clone -b 15.1.1 https://opendev.org/openstack/python-novaclient.git
    cd python-novaclient
    git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/python-novaclient-intel-sgx.patch
    pip install .
    cd ~
    git clone -b 4.0.2 https://opendev.org/openstack/python-openstackclient.git
    cd python-openstackclient
    git am ~/applications.services.cloud.confidential-computing.sgx-hmc-solution/python-openstackclient-intel-sgx.patch
    pip install .
    cd ~
    pip install gnureadline==8.1.2
    pip install python-ironicclient
    pip install python-ironic-inspector-client

    cat <<EOF > ~/inspector_rule_ipmi_credential.yml
    description: "Set IPMI driver_info if no credentials"
    conditions:
      - field: "node://driver_info.ipmi_username"
        op: "is-empty"
      - field: "node://driver_info.ipmi_password"
        op: "is-empty"
    actions:
      - action: "set-attribute"
        path: "driver_info/ipmi_username"
        value: "admin"
      - action: "set-attribute"
        path: "driver_info/ipmi_password"
        value: "admin"
    EOF

    openstack baremetal introspection rule import ~/inspector_rule_ipmi_credential.yml

    cat <<EOF > ~/inspector_rule_deploy_kernel.yml
    description: "Set deploy kernel"
    conditions:
      - field: "node://driver_info.deploy_kernel"
        op: "is-empty"
    actions:
      - action: "set-attribute"
        path: "driver_info/deploy_kernel"
        value: "http://172.16.141.202:8089/ironic-agent.kernel"
    EOF

    openstack baremetal introspection rule import ~/inspector_rule_deploy_kernel.yml

    cat <<EOF > ~/inspector_rule_deploy_ramdisk.yml
    description: "Set deploy ramdisk"
    conditions:
      - field: "node://driver_info.deploy_ramdisk"
        op: "is-empty"
    actions:
      - action: "set-attribute"
        path: "driver_info/deploy_ramdisk"
        value: "http://172.16.141.202:8089/ironic-agent.initramfs"
    EOF

    openstack baremetal introspection rule import ~/inspector_rule_deploy_ramdisk.yml
    ```

2. Switch eth0 of Bare4 to VLAN 142 and Power on Bare4

3. Check Whether Bare4 is Introspected by Ironic (this may take several minutes)

    ```bash
    source src/kayobe-config/etc/kolla/admin-openrc.sh
    openstack baremetal node list
    ```

4. Switch eth0 of Bare4 to VLAN 143

5. Update Info of Bare4

    ```bash
    source src/kayobe-config/etc/kolla/admin-openrc.sh
    openstack baremetal node set <UUID of Bare4> --name baremetal-workload-0 --resource-class sgx_baremetal
    openstack baremetal node add trait <UUID of Bare4> HW_CPU_X86_SGX
    openstack baremetal node set --network-interface flat <UUID of Bare4>
    openstack baremetal node set --property capabilities=boot_mode:uefi <UUID of Bare4>
    openstack baremetal node manage <UUID of Bare4>
    openstack baremetal node provide <UUID of Bare4>
    ```

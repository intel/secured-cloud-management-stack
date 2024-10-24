#!/bin/bash
# Currently support CentOS8.4/CentOS7.9, 1+N deployment, VM instance
set -e

# ******************** Common Configuration ********************
HOST_OS_VERSION="8"
PREPARE_DIR=~/prepare

# ******************** Network Configuration ********************
INTERNAL_NIC="eth0"
INTERNAL_IP="192.168.122.101"
EXTERNAL_NIC="tap0"
EXTERNAL_GATEWAY="192.168.122.1"
EXTERNAL_SUB_RANGE="192.168.122.0/24"
EXTERNAL_POOL_START="192.168.122.111"
EXTERNAL_POOL_END="192.168.122.120"

# ******************** Ironic Configuration ********************
IRONIC_ENABLE="true"
IRONIC_GATEWAY="192.168.122.1"
IRONIC_POOL_START="192.168.122.121"
IRONIC_POOL_END="192.168.122.130"
BM_IPMI_USERNAME="sgx"
BM_IPMI_PASSWORD="123456"

# ******************** SGX DCAP Configuration ********************
EPC_SIZE="131072"
API_KEY=""
USER_PASSWD="pccs1234.."
ADMIN_PASSWD="pccs1234.."

function check_dependency() {
    echo "INFO: Start to check dependency files..."
    if [ ! -f $PREPARE_DIR/kolla-ansible-intel-sgx.patch ]; then
        echo "Error: check dependency files failed, missing kolla-ansible-intel-sgx.patch!"
        exit 1
    fi
    if [ ! -f $PREPARE_DIR/python-openstackclient-intel-sgx.patch ]; then
        echo "Error: check dependency files failed, missing python-openstackclient-intel-sgx.patch!"
        exit 1
    fi
    if [ ! -f $PREPARE_DIR/ubuntu-20.04.raw ]; then
        echo "Error: check dependency files failed, missing vm image ubuntu-20.04.raw!"
        exit 1
    fi
    echo "INFO: Successfully check dependency files."
}

function configure_proxy() {
    #Ask for proxy server
    echo "INFO: Check proxy server configuration for internet connection... "
    if [ "$http_proxy" = "" ]; then
        read -p "Enter your http proxy server address, e.g. http://proxy-server:port (Press ENTER if there is no proxy server) :" http_proxy
        export http_proxy=$http_proxy
    else
        echo "INFO: Get http_proxy: $http_proxy"
    fi
    if [ "$https_proxy" = "" ]; then
        read -p "Enter your https proxy server address, e.g. http://proxy-server:port (Press ENTER if there is no proxy server) :" https_proxy
        export https_proxy=$https_proxy
    else
        echo "INFO: Get https_proxy: $https_proxy"
    fi
    export no_proxy=localhost,127.0.0.1,$INTERNAL_IP
}

function replace_repo() {
    if [ "$HOST_OS_VERSION" = "8" ]; then
        if [ ! -f /etc/yum.repos.d/Centos-8.repo ]; then
            rm -rf /etc/yum.repos.d/*
            curl -L http://mirrors.aliyun.com/repo/Centos-8.repo -o /etc/yum.repos.d/Centos-8.repo
        fi
        if [ ! -f /etc/yum.repos.d/intelsgxstack.repo ]; then
            curl -L https://download.01.org/intelsgxstack/2021-12-08/rhel/intelsgxstack.repo -o /etc/yum.repos.d/intelsgxstack.repo
        fi
    fi
}

function upgrade_kernel_7() {
    if [ "$(rpm -qa | grep ^kernel-ml-5.16.10)" != "" ]; then
        echo "INFO: Kernel already installed."
    else
        if [ ! -f ~/rpmbuild/RPMS/x86_64/kernel-ml-5.16.10-1.el7.x86_64.rpm -o ! -f ~/rpmbuild/RPMS/x86_64/kernel-ml-devel-5.16.10-1.el7.x86_64.rpm ]; then
            echo "INFO: Build kernel..."
            yum install -y centos-release-scl
            yum install -y openssl-devel xz-devel zlib-devel ncurses-devel python3 devtoolset-9-gcc \
            devtoolset-9-binutils devtoolset-9-runtime asciidoc elfutils-libelf-devel newt-devel xmlto audit-libs-devel \
            binutils-devel elfutils-devel java-1.8.0-openjdk-devel libcap-devel numactl-devel \
            python-devel slang-devel pciutils-devel perl-ExtUtils-Embed rpm-build bison gcc net-tools rsync git
            if [ ! -f ~/kernel-ml-5.16.10-1.el7.elrepo.nosrc.rpm ]; then
                curl -L https://mirror.rcg.sfu.ca/mirror/ELRepo/kernel/el7/SRPMS/kernel-ml-5.16.10-1.el7.elrepo.nosrc.rpm -o ~/kernel-ml-5.16.10-1.el7.elrepo.nosrc.rpm 
            fi
            rm -rf ~/rpmbuild
            rpm -i ~/kernel-ml-5.16.10-1.el7.elrepo.nosrc.rpm
            curl -L https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.10.tar.xz -o ~/rpmbuild/SOURCES/linux-5.16.10.tar.xz 
            if [ "$(grep CONFIG_X86_SGX_KVM ~/rpmbuild/SOURCES/config-5.16.10-x86_64)" = "" ]; then
                cat << EOF >> ~/rpmbuild/SOURCES/config-5.16.10-x86_64
CONFIG_X86_SGX=y
CONFIG_X86_SGX_KVM=y
EOF
            fi
            cd ~/rpmbuild
            rpmbuild -bb SPECS/kernel-ml-5.16.spec
            cd ~
        fi
        echo "INFO: Install kernel..."
        rpm -i ~/rpmbuild/RPMS/x86_64/kernel-ml-5.16.10-1.el7.x86_64.rpm
        rpm -i ~/rpmbuild/RPMS/x86_64/kernel-ml-devel-5.16.10-1.el7.x86_64.rpm
    fi
    echo "INFO: Set default kernel..."
    grubby --set-default="/boot/vmlinuz-5.16.10-1.el7.x86_64"
}

function upgrade_kernel_8() {
    if [ "$(rpm -qa | grep ^intel-mvp-mainline-kernel-sgx-kvm)" != "" ]; then
        echo "INFO: Kernel already installed."
    else
        echo "INFO: Install kernel..."
        yum install -y intel-mvp-mainline-kernel-sgx-kvm-5.15.5
    fi
    echo "INFO: Set default kernel..."
    grubby --set-default="/boot/vmlinuz-5.15.5-mvp2.el8.x86_64"
}

function upgrade_kernel() {
    if [ -c /dev/sgx_enclave -a -c /dev/sgx_provision -a -c /dev/sgx_vepc ]; then
        echo "INFO: No need to upgrade kernel, SGX driver exists."
    else
        if [ "$HOST_OS_VERSION" = "7" ]; then
            upgrade_kernel_7
        elif [ "$HOST_OS_VERSION" = "8" ]; then
            upgrade_kernel_8
        else
            echo "ERROR: Invalid HOST_OS_VERSION!"
            exit 1
        fi
        if [ "$(grep "^sgx_prv" /etc/group)" = "" ]; then
            groupadd sgx_prv
        fi
        cat << EOF > /etc/udev/rules.d/10-sgx.rules
SUBSYSTEM=="misc",KERNEL=="enclave",MODE="0666"
SUBSYSTEM=="misc",KERNEL=="provision",GROUP="sgx_prv",MODE="0660"
SUBSYSTEM=="misc",KERNEL=="sgx_enclave",MODE="0666",SYMLINK+="sgx/enclave"
SUBSYSTEM=="misc",KERNEL=="sgx_provision",GROUP="sgx_prv",MODE="0660",SYMLINK+="sgx/provision"
EOF
        udevadm trigger
        read -p "Need to reboot, reboot now? [Y/N]" reboot_now
        if [ "$reboot_now" = "Y"  -o "$reboot_now" = "y" ]; then
            reboot
        else
            echo "WARNING: Please reboot manually!"
            exit 1
        fi
    fi  
}

function init_conf() {
    # Install dependencies
    if [ "$HOST_OS_VERSION" = "7" ]; then
        yum install -y python-devel python3-devel libffi-devel gcc openssl-devel libselinux-python libselinux-python3 python3-pip python-virtualenv git
        if [ ! -f /usr/bin/pip ]; then
            if [ ! -f ~/get-pip.py ]; then
                curl -L https://bootstrap.pypa.io/pip/2.7/get-pip.py -o ~/get-pip.py
            fi
            python ~/get-pip.py
        fi
    fi
    if [ "$HOST_OS_VERSION" = "8" ]; then
        yum install -y python3-devel libffi-devel gcc openssl-devel python3-libselinux python3-pip python3-virtualenv git
        alternatives --set python /usr/bin/python3
        pip3 install docker
    fi
    if [ ! -d ~/openstack ]; then
        mkdir -p ~/openstack
    fi
    if [ -d /etc/kolla ]; then
        rm -rf /etc/kolla
    fi
    mkdir -p /etc/kolla
    chown $USER:$USER /etc/kolla
    mkdir -p /etc/kolla/config
    if [ ! -d /etc/ansible ]; then
        mkdir -p /etc/ansible
    fi
    if [ ! -d ~/openstack/venv ]; then
        python3 -m venv ~/openstack/venv
    fi
    source ~/openstack/venv/bin/activate
    pip install -U pip setuptools
    pip install 'ansible<2.10'
    # Patch kolla-ansible
    if [ ! -d ~/openstack/kolla-ansible ]; then
        git clone https://github.com/openstack/kolla-ansible ~/openstack/kolla-ansible
    fi
    if [ ! -d ~/openstack/kolla-ansible/ansible/roles/dcap ]; then
        cd ~/openstack/kolla-ansible
        git checkout -b train-9.3.2 tags/9.3.2
        git -c user.email="your@email.com" -c user.name="YourName" am $PREPARE_DIR/kolla-ansible-intel-sgx.patch
        cd ~
    fi
    cat << EOF > ~/openstack/kolla-ansible/ansible/roles/nova-cell/templates/qemu.conf.j2
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
    if [ "$(grep false ~/openstack/kolla-ansible/ansible/roles/dcap/tasks/pull.yml)" = "" ]; then
        sed -i '/when/a\    - false' ~/openstack/kolla-ansible/ansible/roles/dcap/tasks/pull.yml
    fi
    if [ ! -d ~/openstack/kolla-ansible/ansible/group_vars/compute ] ; then
        mkdir ~/openstack/kolla-ansible/ansible/group_vars/compute
        cat << EOF > ~/openstack/kolla-ansible/ansible/group_vars/compute/sgx.yml
---
enable_sgx: true
EOF
    fi
    sed -r -i 's|^docker_yum_url:(.)*|docker_yum_url: "https://download.docker.com/linux/centos"|' ~/openstack/kolla-ansible/ansible/roles/baremetal/defaults/main.yml
    # Install kolla-ansible
    pip install ~/openstack/kolla-ansible
    # Modify configuration files
    if [ ! -f /etc/kolla/passwords.yml ]; then
        cp -r ~/openstack/venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/
        kolla-genpwd
    fi
    if [ ! -f ~/openstack/hosts ]; then
        cp ~/openstack/venv/share/kolla-ansible/ansible/inventory/* ~/openstack/
        cp ~/openstack/all-in-one ~/openstack/hosts
    fi
    cat << EOF > /etc/ansible/ansible.cfg
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOF
    local USER_PASSWD_HASH="$(echo -n "$USER_PASSWD" | sha512sum | tr -d '[:space:]-')"
    local ADMIN_PASSWD_HASH="$(echo -n "$ADMIN_PASSWD" | sha512sum | tr -d '[:space:]-')"
    cat << EOF > /etc/kolla/globals.yml
---
# common
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "train"
openstack_tag_suffix: "-centos8s"
node_custom_config: "/etc/kolla/config"

# network
kolla_internal_vip_address: "$INTERNAL_IP"
network_interface: "$INTERNAL_NIC"
neutron_external_interface: "$EXTERNAL_NIC"
enable_haproxy: "no"
enable_neutron_provider_networks: "yes"

# dcap
dcap_api_key: "$API_KEY"
dcap_proxy: "$https_proxy"
dcap_host: "0.0.0.0"

dcap_user_password_hash: "$USER_PASSWD_HASH"
dcap_admin_password_hash: "$ADMIN_PASSWD_HASH"
distro_python_version: "3.6"

# others
neutron_type_drivers: flat,vlan,vxlan
neutron_tenant_network_types: flat,vlan,vxlan
selinux_state: "disabled"
EOF
    if [ $IRONIC_ENABLE = "true" ]; then
        # Check ironic required files
        if [ ! -f $PREPARE_DIR/ipa/ipa.initramfs ]; then
            echo "Error: check dependency files failed, missing ipa/ipa.initramfs!"
            exit 1
        fi
        if [ ! -f $PREPARE_DIR/ipa/ipa.kernel ]; then
            echo "Error: check dependency files failed, missing ipa/ipa.kernel!"
            exit 1
        fi
        if [ ! -f $PREPARE_DIR/ubuntu-20.04-uefi.raw ]; then
            echo "Error: check dependency files failed, missing bm image ubuntu-20.04-uefi.raw!"
            exit 1
        fi
        cat << EOF >> /etc/kolla/globals.yml
# ironic related
enable_ironic: "yes"
enable_ironic_ipxe: "yes"
ironic_dnsmasq_interface: "$INTERNAL_NIC"
ironic_ipxe_port: "8089"
enable_ironic_neutron_agent: "yes"
enable_ironic_pxe_uefi: "yes"
enable_iscsid: "yes"
ironic_cleaning_network: "provision-net"
ironic_dnsmasq_dhcp_range: "$IRONIC_POOL_START,$IRONIC_POOL_END"
ironic_dnsmasq_default_gateway: "$IRONIC_GATEWAY"
ironic_inspector_kernel_cmdline_extras:
- ipa-collect-lldp=1
- ipa-inspection-collectors=default,logs,pci-devices
- ipa-inspection-benchmarks=
EOF
        cat << EOF > /etc/kolla/config/ironic-inspector.conf
[processing]
processing_hooks = ramdisk_error,scheduler,validate_interfaces,capabilities,pci_devices,local_link_connection,lldp_basic,sgx
store_data = database
node_not_found_hook = enroll
add_ports = pxe
keep_ports = present
always_store_ramdisk_logs = True

[discovery]
enroll_node_driver = ipmi
EOF
        cat << EOF > /etc/kolla/config/ironic.conf
[DEFAULT]
enabled_hardware_types = ipmi
enabled_boot_interfaces = pxe
default_boot_interface = pxe
enabled_console_interfaces = ipmitool-socat,no-console
default_console_interface = ipmitool-socat
enabled_deploy_interfaces = direct,iscsi
default_deploy_interface = iscsi
enabled_inspect_interfaces = inspector,no-inspect
default_inspect_interface = inspector
enabled_management_interfaces = ipmitool
default_management_interface = ipmitool
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron
enabled_power_interfaces = ipmitool
default_power_interface = ipmitool
enabled_raid_interfaces = agent,no-raid
default_raid_interface = no-raid
enabled_rescue_interfaces = agent,no-rescue
default_rescue_interface = no-rescue
enabled_vendor_interfaces = ipmitool,no-vendor
default_vendor_interface = no-vendor

[neutron]
provisioning_network = provision-net

[deploy]
default_boot_option = local
EOF
        if [ ! -d /etc/kolla/config/ironic ]; then
        mkdir -p /etc/kolla/config/ironic
        cp $PREPARE_DIR/ipa/ipa.initramfs /etc/kolla/config/ironic/ironic-agent.initramfs
        cp $PREPARE_DIR/ipa/ipa.kernel /etc/kolla/config/ironic/ironic-agent.kernel
        fi
    fi
    cat << EOF > /etc/kolla/config/nova.conf
[DEFAULT]
force_config_drive = True

[libvirt]
sgx_epc_mb = $EPC_SIZE
cpu_mode = host-passthrough
EOF
    if [ "$EXTERNAL_NIC" = "tap0" ]; then
        if [ "$(ip addr | grep tap0)" != "" ]; then
            ip tuntap del dev tap0 mode tap
        fi
        ip tuntap add dev tap0 mode tap
    fi
    echo "INFO: Successfully install dependencies and init configurations."
}

function bootstrap_server() {
    source ~/openstack/venv/bin/activate
    kolla-ansible -i ~/openstack/hosts bootstrap-servers
    if [ "$https_proxy" != "" ]; then
        if [ ! -d /etc/systemd/system/docker.service.d ]; then
            mkdir -p /etc/systemd/system/docker.service.d
        fi
        cat << EOF > /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTPS_PROXY=$https_proxy" "NO_PROXY=localhost,127.0.0.1,$INTERNAL_IP"
EOF
        systemctl daemon-reload
        systemctl restart docker
    fi
    echo "INFO: Successfully bootstrap server."
}

function do_prechecks() {
    source ~/openstack/venv/bin/activate
    kolla-ansible -i ~/openstack/hosts prechecks
    echo "INFO: Successfully do prechecks."
}

function deploy_cloud() {
    if [ "$(docker images | grep kolla)" = "" ]; then
        echo "INFO: Load local openstack docker images..."
        docker load -i $PREPARE_DIR/openstack-train.tar
    fi
    if [ "$(docker images | grep custom)" = "" ]; then
        echo "INFO: Load local dcap docker images..."
        docker load -i $PREPARE_DIR/dcap.tar
    fi
    source ~/openstack/venv/bin/activate
    kolla-ansible -i ~/openstack/hosts deploy
    echo "INFO: Successfully deploy OpenStack."
}

function post_deploy() {
    source ~/openstack/venv/bin/activate
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    fi
    if [ ! -f /etc/kolla/admin-openrc.sh ]; then
        kolla-ansible post-deploy
    fi
    . /etc/kolla/admin-openrc.sh
    if [ ! -d ~/openstack/python-openstackclient ]; then
        git clone -b 4.0.2 https://github.com/openstack/python-openstackclient.git ~/openstack/python-openstackclient
        cd ~/openstack/python-openstackclient
        git -c user.email="your@email.com" -c user.name="YourName" am $PREPARE_DIR/python-openstackclient-intel-sgx.patch
        cd ~
    fi
    pip install ~/openstack/python-openstackclient
    pip install openstacksdk==1.2.0
    if [ "$EXTERNAL_NIC" = "tap0" ]; then
        ip link set br-ex up
        if [ "$(ip addr | grep br-ex | grep 10.0.2.1)" = "" ]; then
            ip addr add 10.0.2.1/24 dev br-ex
        fi
        iptables -t nat -A POSTROUTING -o $INTERNAL_NIC -j MASQUERADE
        local dnss=$(cat /etc/resolv.conf | grep "^nameserver" | while read line; \
            do dns_line=`echo "$line" | awk '{print $2}'`; echo -n "--dns-nameserver \
            $dns_line "; done)
        if [ "$(openstack network list | grep public_net)" = "" ]; then
            openstack network create --external --provider-physical-network physnet1 --provider-network-type flat --share --disable-port-security public_net
        fi
        if [ "$(openstack subnet list | grep public_subnet)" = "" ]; then
            openstack subnet create --subnet-range 10.0.2.0/24 --gateway  10.0.2.1 --allocation-pool start=10.0.2.2,end=10.0.2.254 $dnss --network public_net public_subnet
        fi
        if [ "$(openstack network list | grep private_net)" = "" ]; then
            openstack network create --provider-network-type vxlan --share --disable-port-security private_net
        fi
        if [ "$(openstack subnet list | grep private_subnet)" = "" ]; then
            openstack subnet create --subnet-range 10.0.10.0/24 --gateway 10.0.10.1 --allocation-pool start=10.0.10.2,end=10.0.10.254 $dnss --network private_net private_subnet
        fi
        if [ "$(openstack router list)" = "" ]; then
            openstack router create demo-router
            openstack router add subnet demo-router private_subnet
            openstack router set --enable-snat --external-gateway  public_net --fixed-ip subnet=public_subnet,ip-address=10.0.2.98 demo-router
        fi
    else
        if [ "$(openstack network list)" = "" ]; then
            openstack network create --provider-physical-network physnet1 --provider-network-type flat --share --disable-port-security provision-net
        fi
        if [ "$(openstack subnet list)" = "" ]; then
            openstack subnet create --subnet-range $EXTERNAL_SUB_RANGE --allocation-pool start=$EXTERNAL_POOL_START,end=$EXTERNAL_POOL_END --network provision-net --gateway $EXTERNAL_GATEWAY provision-net-sub
        fi
    fi
    if [ "$(openstack keypair list)" = "" ]; then
        openstack keypair create --public-key ~/.ssh/id_rsa.pub cloud-key
    fi
    echo "INFO: Successfully do post deploy configuration."
}

function create_vm() {
    source ~/openstack/venv/bin/activate
    . /etc/kolla/admin-openrc.sh
    local project_id=$(openstack project list | awk '/ admin / {print $2}')
    openstack quota set --sgx-epc $EPC_SIZE ${project_id}
    if [ "$(openstack flavor list | grep sgx-2c-4g-1g)" = "" ]; then
        openstack flavor create --ram 4096 --vcpus 2 --disk 20 \
        --property resources:CUSTOM_SGX_EPC_MB=1024 \
        --property trait:HW_CPU_X86_SGX='required' sgx-2c-4g-1g
    fi
    if [ "$(openstack image list | grep sgx-vm-image)" = "" ]; then
        openstack image create --file $PREPARE_DIR/ubuntu-20.04.raw --disk-format raw \
        --container-format bare --property usage_type='common' \
        --property os_distro=others --property hw_qemu_guest_agent=no \
        --property os_admin_user=root \
        --property trait:HW_CPU_X86_SGX='required' \
        --public sgx-vm-image
    fi
    if [ "$EXTERNAL_NIC" = "tap0" ]; then
        local INSTANCE_NETWOTK="private_net"
    else
        local INSTANCE_NETWOTK="provision-net"
    fi
    if [ "$(openstack server list | grep sgx-virtual-instance)" = "" ]; then
        openstack server create --flavor sgx-2c-4g-1g --network $INSTANCE_NETWOTK \
        --image sgx-vm-image  --key-name cloud-key sgx-virtual-instance
    fi
    echo "INFO: Get IP address of vm..."
    local vm_ip=""
    while true ; do
        vm_ip=$(openstack server list | grep sgx-virtual-instance | awk '{print $8}')
        if [ "$vm_ip" = "|" -o "$vm_ip" = "" ]; then
            echo "WARNING: Not get IP address of vm yet! Wait for 10s..."
            sleep 10
        else
            echo "INFO: Successfully get IP address of vm: $vm_ip"
            break
        fi
    done
}

function register_bm() {
    source ~/openstack/venv/bin/activate
    . /etc/kolla/admin-openrc.sh
    pip install gnureadline==8.1.2 python-ironicclient python-ironic-inspector-client
    if [ -f ~/inspector_rule_ipmi_credential.yml ]; then
        rm -f ~/inspector_rule_ipmi_credential.yml
    fi
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
    value: "$BM_IPMI_USERNAME"
  - action: "set-attribute"
    path: "driver_info/ipmi_password"
    value: "$BM_IPMI_PASSWORD"
EOF
    if [ ! -f ~/inspector_rule_deploy_kernel.yml ]; then
        rm -f ~/inspector_rule_deploy_kernel.yml
    fi
    cat <<EOF > ~/inspector_rule_deploy_kernel.yml
description: "Set deploy kernel"
conditions:
  - field: "node://driver_info.deploy_kernel"
    op: "is-empty"
actions:
  - action: "set-attribute"
    path: "driver_info/deploy_kernel"
    value: "http://$INTERNAL_IP:8089/ironic-agent.kernel"
EOF
    if [ -f ~/inspector_rule_deploy_ramdisk.yml ]; then
        rm -f ~/inspector_rule_deploy_ramdisk.yml
    fi
    cat <<EOF > ~/inspector_rule_deploy_ramdisk.yml
description: "Set deploy ramdisk"
conditions:
  - field: "node://driver_info.deploy_ramdisk"
    op: "is-empty"
actions:
  - action: "set-attribute"
    path: "driver_info/deploy_ramdisk"
    value: "http://$INTERNAL_IP:8089/ironic-agent.initramfs"
EOF
    local uuid=""
    if [ "$(openstack baremetal introspection rule list | grep IPMI)" != "" ]; then
        uuid=$(openstack baremetal introspection rule list | grep IPMI | awk '{print $2}')
        openstack baremetal introspection rule delete $uuid
    fi
    if [ "$(openstack baremetal introspection rule list | grep ramdisk)" != "" ]; then
        uuid=$(openstack baremetal introspection rule list | grep ramdisk | awk '{print $2}')
        openstack baremetal introspection rule delete $uuid
    fi
    if [ "$(openstack baremetal introspection rule list | grep kernel)" != "" ]; then
        uuid=$(openstack baremetal introspection rule list | grep kernel | awk '{print $2}')
        openstack baremetal introspection rule delete $uuid
    fi
    openstack baremetal introspection rule import ~/inspector_rule_ipmi_credential.yml
    openstack baremetal introspection rule import ~/inspector_rule_deploy_kernel.yml
    openstack baremetal introspection rule import ~/inspector_rule_deploy_ramdisk.yml
    echo "Please power on baremetal node and go into PXE."
    local is_done=""
    while true ; do
        read -p "Already done? [Y/N]" is_done
        if [[ $is_done == "y" || $is_done == "Y" ]]; then
            break
        else
            echo "Please power on baremetal node and go into PXE."
        fi
    done
    echo "Get baremetal node list..."
    while true ; do
        if [ "$(openstack baremetal node list | grep None)" != "" ] ; then
            break
        else
            echo "Warning: not get baremetal node yet!"
            sleep 2
        fi
    done
    uuid=$(openstack baremetal node list | grep None |awk '{print $2}')
    echo "Successfully get uuid: $uuid"
    openstack baremetal node set $uuid --name baremetal-workload-0 --resource-class sgx_baremetal
    openstack baremetal node add trait $uuid HW_CPU_X86_SGX
    openstack baremetal node set --network-interface flat $uuid
    openstack baremetal node set --property capabilities=boot_mode:uefi $uuid
    local state=$(echo $(openstack baremetal node show $uuid | grep provision_state) | awk '{print $4}')
    if [[ $state == "available" || $state == "active" ]]; then
        echo "Already register baremetal node!"
        exit 0
    fi
    if [[ $state != "enroll" ]]; then
        echo "Error: invalid state $state!"
        exit 1
    fi
    echo "Manage baremetal node..."
    openstack baremetal node manage $uuid
    echo "Wait for baremetal node state to change..."
    while true ; do      
	    state=$(echo $(openstack baremetal node show $uuid | grep provision_state) | awk '{print $4}')
        if [[ $state == "manageable" ]] ; then
            break
        else
            echo "Warning: state not change yet!"
            sleep 2
        fi
    done
    local need_clean=""
    read -p "Need to manually clean baremetal node?[Y/N]" need_clean
    if [[ $need_clean == "y" || $need_clean == "Y" ]]; then
        echo "Start to clean baremetal node..."
        openstack baremetal node clean $uuid --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
        echo "Wait for cleaning to finish..."
        sleep 10
        while true ; do      
	        state=$(echo $(openstack baremetal node show $uuid | grep provision_state) | awk '{print $4}')
            if [[ $state == "manageable" ]] ; then
                break
            else
                echo "Warning: state not change yet!"
                sleep 10
            fi
        done
        echo "Successfully clean baremetal node!"
    fi
    echo "Provide baremetal node..."
    openstack baremetal node provide $uuid
    echo "Wait for baremetal node state to change..."
    while true ; do      
	    state=$(echo $(openstack baremetal node show $uuid | grep provision_state) | awk '{print $4}')
        if [[ $state == "available" ]] ; then
            break
        else
            echo "Warning: state not change yet!"
            sleep 2
        fi
    done
    echo "Successfully register baremetal node!"
}

function create_bm() {
    source ~/openstack/venv/bin/activate
    . /etc/kolla/admin-openrc.sh
    if [ "$(openstack flavor list | grep sgx-baremetal-2c-4g)" == "" ]; then
        openstack flavor create --ram 4096 --vcpus 2 --disk 20 \
        --property resources:CUSTOM_SGX_EPC_MB=0 \
        --property trait:HW_CPU_X86_SGX='required' \
        --property resources:CUSTOM_SGX_BAREMETAL=1 \
        --property resources:VCPU=0 \
        --property resources:MEMORY_MB=0 \
        --property resources:DISK_GB=0 sgx-baremetal-2c-4g
    fi
    if [ "$(openstack image list | grep sgx-bare-metal-image)" == "" ]; then
        openstack image create --file $PREPARE_DIR/ubuntu-20.04-uefi.raw --disk-format raw \
        --container-format bare --property usage_type='common' \
        --property os_distro=others --property hw_qemu_guest_agent=no \
        --property os_admin_user=root \
        --property trait:HW_CPU_X86_SGX='required' \
        --public sgx-bare-metal-image
    fi
    if [ "$EXTERNAL_NIC" = "tap0" ]; then
        local INSTANCE_NETWOTK="private_net"
    else
        local INSTANCE_NETWOTK="provision-net"
    fi
    if [[ "$(openstack server list | grep sgx-bare-metal-instance)" == "" ]]; then
        openstack server create --flavor sgx-baremetal-2c-4g \
        --network $INSTANCE_NETWOTK \
        --image  sgx-bare-metal-image \
        --key-name cloud-key sgx-bare-metal-instance
    fi
    echo "Get IP address of baremetal node..."
    local bm_ip=""
    while true ; do
        bm_ip=$(openstack server list | grep sgx-bare-metal-instance | awk '{print $8}')
        if [[ $bm_ip == "|" || $bm_ip == "" ]]; then
            echo "Warning: not get IP address of baremetal node yet!"
            sleep 10
        else
            echo "Successfully get IP address of baremetal node: $bm_ip"
            break
        fi
    done
}

function echo_help() {
    echo -e "First of all, please modify the configurations at the beginning of this script, then follow the following steps:\n$0 kernel\n$0 init\n$0 bootstrap\n$0 precheck\n$0 deploy\n$0 post_deploy\n$0 create_vm"
}

check_dependency
configure_proxy
replace_repo
case $1 in
    kernel) upgrade_kernel   
            ;;
    init) init_conf
            ;;
    bootstrap) bootstrap_server
	        ;;
    precheck) do_prechecks
	        ;;
    deploy) deploy_cloud
	        ;;
    post_deploy) post_deploy
            ;;
    create_vm) create_vm
            ;;
    register_bm) register_bm
            ;;
    create_bm) create_bm
            ;;
    *) echo_help
            ;;
esac

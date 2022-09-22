# Kolla Ansible

For more information about Kolla-Ansible, please refer to
[Kolla Ansible](https://docs.openstack.org/kolla-ansible/latest/).
Patch [kolla-ansible-intel-sgx.patch](../../kolla-ansible-intel-sgx.patch)
is based on <https://github.com/openstack/kolla-ansible/tree/9.3.2>

## Add support for the deployments of DCAP and Skyline

### Design

* Add Ansible role dcap and skyline to Kolla-Ansible

  Template module of Ansible is used to generate configuration files
  and copy to deployment hosts.
  Docker module of Ansible is used to create containers of SKyline and DCAP,
  which maps configuration files on the host to files in containers.

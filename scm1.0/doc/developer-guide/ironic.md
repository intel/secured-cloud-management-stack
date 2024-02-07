# Ironic Relates

For more information about Ironic components, please refer to
[Ironic](https://docs.openstack.org/ironic/latest/),
[Ironic Inspector](https://docs.openstack.org/ironic-inspector/latest/)(II),
[Ironic Python Agent](https://docs.openstack.org/ironic-python-agent/latest/)(IPA), and
[Ironic Python Agent Builder](https://docs.openstack.org/ironic-python-agent-builder/latest/)(IPAB).

* patch [ironic-inspector-intel-sgx.patch](../../ironic-inspector-intel-sgx.patch) is based on
<https://github.com/openstack/ironic-inspector/tree/stable/train>.
* patch [ironic-python-agent-builder-intel-sgx.patch](../../ironic-python-agent-builder-intel-sgx.patch) is based on
<https://github.com/openstack/ironic-python-agent-builder/tree/2.7.0>.
* patch [ironic-python-agent-intel-sgx.patch](../../ironic-python-agent-builder-intel-sgx.patch) is based on
<https://github.com/openstack/ironic-python-agent/tree/5.0.4>.

## Add spport for inspecting SGX features

### Design

* Obtain SGX info by IPA

  SGX info can be obtained from bare metal's CPUs.
  When inspecting a bare metal, IPA can use `cpuid` and `rdmsr` to collect this info,
  and send info to the Ironic Inspector (II).

* Add a hook to II to parse SGX info

  Normally, II uses hooks to parse infos collected from IPA,
  and set corresponding properties to bare metal node.
  A new hook named sgx is added to II. To enable this hook,
  it should be added to the configuration option `processing_hooks` in `inspector.conf`.

  ```ini
  [processing]
  processing_hooks = ..., sgx
  ```

* Build IPA image with packages `cpuid` and `msr-tools`

  As IPA uses `cpuid` and `rdmsr` to collect SGX info,
  packages of `cpuid` and `msr-tools` should be installed in IPA image.
  'cpuid' and 'msr-tools' are added to IPAB.

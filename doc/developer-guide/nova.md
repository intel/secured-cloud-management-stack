# Nova

For more information about Nova, please refer to
[nova doc](https://docs.openstack.org/nova/train/).
The patch [nova-intel-sgx.patch](../../nova-intel-sgx.patch)
is based on <https://github.com/openstack/nova/tree/20.6.1>

## Add Support of SGX in Nova

### Requirements

* Nova compute hosts must be INTEL hardware capable of supporting SGX, and
  SGX control options are successfully enabled in BIOS.
  It is entirely possible for the compute plane to be a mix of hardware which
  can and cannot support SGX, the maximum number of simultaneously
  running guests with SGX will be limited by the quantity and quality of
  SGX-capable hardware available.

* The following software stack is configured on Nova compute hosts:

  - kernel >= 4.16
  - QEMU >= 2.12
  - libvirt >= 4.5

### Design

In order for users to be able to create SGX-enabled instances,
The following adjustments need to be made to Nova.

* Support for Creating SGX-enabled flavors and images

  SGX-enabled flavor has `resources:CUSTOM_SGX_EPC_MB=xxx` and
  `trait:HW_CPU_X86_SGX=requried` in its extra specs. The value of `xxx`
  represents the memory size of EPC that guest needs, which is greater than 0 and
  less than the SGX-capable host's supply. SGX-enabled image has the property
  of `trait:HW_CPU_X86_SGX=required`.

* Add `libvirt.sgx_epc_mb` configuration option in `nova.conf`

  `sgx_epc_mb` represents the EPC memory that
  an SGX-capable compute host can provide to guests. For example:

  ```ini
  [libvirt]
  sgx_epc_mb = 10240
  ```

* Add `libvirt.sgx_features` configuration option in `nova.conf`

  `sgx_features` represents the host's SGX CPU features which
  should be passed to SGX instances. For example:

  ```ini
  [libvirt]
  sgx_features = sgx, sgxlc, sgx1, sgx-debug, sgx-mode64, sgx-provisionkey, sgx-tokenkey
  ```

  > **caution**
  >
  > The way Linux gets CPU features is through the CPUID instruction.
  > Libvirt file `/var/share/libvirt/cpu-map/x86-features.xml` defines
  > CPUID's input and output of each CPU feature. Through this file and
  > executing the CPUID instruction, Libvirt can obtain the features
  > supported by host's CPU. Features configured in option
  > `sgx_features` should be supported by host. Normally,
  >  `/var/share/libvirt/cpu-map/x86-features.xml` does not contain
  >  definitions of SGX features. The following needs to be added.
  >
  > ```xml
  > <!-- SGX features -->
  >   <feature name="sgx">
  >     <cpuid eax_in='0x07' ecx_in='0x00' ebx='0x00000004'/>
  >   </feature>
  >   <feature name="sgxlc">
  >     <cpuid eax_in='0x07' ecx_in='0x00' ecx='0x40000000'/>
  >   </feature>
  >   <feature name="sgx1">
  >     <cpuid eax_in='0x12' ecx_in='0x00' eax='0x00000001'/>
  >   </feature>
  >   <feature name="sgx-debug">
  >     <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000002'/>
  >   </feature>
  >   <feature name="sgx-mode64">
  >     <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000004'/>
  >   </feature>
  >   <feature name="sgx-provisionkey">
  >     <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000010'/>
  >   </feature>
  >   <feature name="sgx-tokenkey">
  >     <cpuid eax_in='0x12' ecx_in='0x01' eax='0x00000020'/>
  >   </feature>
  > ```

* Add handling of generating SGX Libvirt xml in Nova's Libvirt driver

  The format of SGX Libvirt xml is as follows.

  ```xml
  <qemu:commandline>
      <qemu:arg value='-cpu'/>
      <qemu:arg value='host,+sgx,+sgxlc'/>
      <qemu:arg value='-object'/>
      <qemu:arg value='memory-backend-epc,id=mem1,size=8M,prealloc=on'/>
      <qemu:arg value='-M'/>
      <qemu:arg value='sgx-epc.0.memdev=mem1'/>
  </qemu:commandline>
  ```

  Size of EPC can be obtained from extra spec (`resources:CUSTOM_SGX_EPC_MB=xxx`) of the specified flavor.
  SGX CPU features is configured directly by `sgx_features` in `nova.conf`.

# Diskimage Builder

For more information about DISKimage Builder (DIB),
please refer to [DIB]<https://docs.openstack.org/diskimage-builder/latest>
Patch [dib-intel-tdx.patch](../../dib-intel-tdx.patch) is based on
<https://github.com/openstack/diskimage-builder/tree/3.20.3>.

## Add support for building OS image with TDX drivers

### Design

We add `intel-tdx` element under `diskimage-builder/diskimage_builder/elements/intel-tdx`.

* extra-data.d

    - Add option `DIB_KERNEL_PATH` in `extra-data.d` file.
    - Pull in extra data from the host environment that hooks may need during image creation. This should copy kernel binary packages under `$TMP_HOOKS_PATH/tmp/kernel`.
    - Contents placed under $TMP_HOOKS_PATH will be available at /tmp/in_target.d inside the chroot.

* install.d

    - Runs after pre-install.d in the chroot. Here kernel is updated.

* element-deps

    - The intel-tdx element depends on the following elements:
        - package-installs

* pkg-map

    - The packages listed in this file will be installed in the chroot when doing the `package-installs` step.

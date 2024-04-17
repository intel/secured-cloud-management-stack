# Python Nova Client

For more information about python-novaclient, please refer to
[python-novaclient doc](https://docs.openstack.org/python-novaclient/train/).
The patch [python-novaclient-intel-sgx.patch](../../python-novaclient-intel-sgx.patch)
is based on <https://opendev.org/openstack/python-novaclient/src/tag/15.1.1>.

## Add support for SGX EPC Quota

### Design

* Result of `nova quota-show` contains quota of SGX EPC

    ```console
    $ nova quota-show
    +----------------------+-------+
    | Quota                | Limit |
    +----------------------+-------+
    | instances            | 10    |
    | cores                | 20    |
    | ram                  | 51200 |
    | metadata_items       | 128   |
    | key_pairs            | 100   |
    | server_groups        | 10    |
    | server_group_members | 10    |
    | sgx_epc              | 3096  |
    +----------------------+-------+
    ```

* Result of `quota-defaults` contains quota of SGX EPC

    ```console
    $ nova quota-defaults
    +----------------------+-------+
    | Quota                | Limit |
    +----------------------+-------+
    | instances            | 10    |
    | cores                | 20    |
    | ram                  | 51200 |
    | metadata_items       | 128   |
    | key_pairs            | 100   |
    | server_groups        | 10    |
    | server_group_members | 10    |
    | sgx_epc              | 3096  |
    +----------------------+-------+
    ```

* `nova quota-update` can update quota of SGX EPC for the specified tenant or user

    ```console
    $ nova quota-update --sgx-epc 1024 1daaab9a50584d5cbeb5327879b169f8
    ```

* Result of `nova quota-class-show` contains quota of SGX EPC

    ```console
    $ nova quota-class-show default
    +----------------------+-------+
    | Quota                | Limit |
    +----------------------+-------+
    | instances            | 10    |
    | cores                | 20    |
    | ram                  | 51200 |
    | metadata_items       | 128   |
    | key_pairs            | 100   |
    | server_groups        | 10    |
    | server_group_members | 10    |
    | sgx_epc              | 3096  |
    +----------------------+-------+
    ```

* `nova quota-class-update` can update quota of SGX EPC for the specified class

  ```console
  $ nova quota-class-update --sgx-epc 4096 default
  ```

# Python OpenStack Client

For more information about python-openstackclient, please refer to
[python-openstackclient doc](https://docs.openstack.org/python-openstackclient/train/).
The patch [python-openstackclient-intel-sgx.patch](../../python-openstackclient-intel-sgx.patch)
is based on <https://opendev.org/openstack/python-openstackclient/src/tag/4.0.2>.

## Add support for SGX EPC Quota

### Design

* Result of `openstack quota list --compute` contains SGX EPC

    ```console
    $ openstack quota list
    +----------------------------------+-------+-----------+----------------+-----------------------------+--------------------------+-----------+-----------+----------------+-------+---------+---------------+----------------------+
    | Project ID                       | Cores | Fixed IPs | Injected Files | Injected File Content Bytes | Injected File Path Bytes | Instances | Key Pairs | Metadata Items |   Ram | SGX EPC | Server Groups | Server Group Members |
    +----------------------------------+-------+-----------+----------------+-----------------------------+--------------------------+-----------+-----------+----------------+-------+---------+---------------+----------------------+
    | 1daaab9a50584d5cbeb5327879b169f8 |    20 |        -1 |              5 |                       10240 |                      255 |        10 |       100 |            128 | 51200 |    1024 |            10 |                   10 |
    +----------------------------------+-------+-----------+----------------+-----------------------------+--------------------------+-----------+-----------+----------------+-------+---------+---------------+----------------------+
    ```

* Result of `openstack quota-show` contains SGX EPC

    ```console
    $ openstack quota show 1daaab9a50584d5cbeb5327879b169f8
    +----------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Field                | Value                                                                                                                                                                                      |
    +----------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | cores                | 20                                                                                                                                                                                         |
    | fixed-ips            | -1                                                                                                                                                                                         |
    | floating-ips         | 50                                                                                                                                                                                         |
    | injected-file-size   | 10240                                                                                                                                                                                      |
    | injected-files       | 5                                                                                                                                                                                          |
    | injected-path-size   | 255                                                                                                                                                                                        |
    | instances            | 10                                                                                                                                                                                         |
    | key-pairs            | 100                                                                                                                                                                                        |
    | location             | Munch({'cloud': '', 'region_name': 'RegionOne', 'zone': None, 'project': Munch({'id': '1daaab9a50584d5cbeb5327879b169f8', 'name': 'admin', 'domain_id': None, 'domain_name': 'Default'})}) |
    | networks             | 100                                                                                                                                                                                        |
    | ports                | 500                                                                                                                                                                                        |
    | project              | 1daaab9a50584d5cbeb5327879b169f8                                                                                                                                                           |
    | project_name         | admin                                                                                                                                                                                      |
    | properties           | 128                                                                                                                                                                                        |
    | ram                  | 51200                                                                                                                                                                                      |
    | rbac_policies        | 10                                                                                                                                                                                         |
    | routers              | 10                                                                                                                                                                                         |
    | secgroup-rules       | 100                                                                                                                                                                                        |
    | secgroups            | 10                                                                                                                                                                                         |
    | server-group-members | 10                                                                                                                                                                                         |
    | server-groups        | 10                                                                                                                                                                                         |
    | sgx-epc              | 1024                                                                                                                                                                                       |
    | subnet_pools         | -1                                                                                                                                                                                         |
    | subnets              | 100                                                                                                                                                                                        |
    +----------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    ```

* `openstack quota set --sgx-epc 2048 ` can update quota of SGX EPC for the specified tenant or class

    ```console
    $ openstack quota set --sgx-epc 2048 1daaab9a50584d5cbeb5327879b169f8
    ```

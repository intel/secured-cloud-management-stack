# Set quota for SGX EPC by client

## Python Nova Client

1. Update SGX EPC quota for a specified project/user

    ```bash
    nova quota-update --sgx-epc <sgx-epc> <project-id/user-id>
    ```

2. Update SGX EPC quota for a specified quota class

    ```bash
    nova quota-class-update --sgx-epc <sgx-epc> <class>
    ```

## Python OpenStack Client

1. Update SGX EPC quota for a specified project

    ```bash
    openstack quota set --sgx-epc <sgx-epc> <project_id>
    ```

2. Update SGX EPC quota for a specified class

    ```bash
    openstack quota set --class --sgx-epc <sgx-epc> <class>
    ```

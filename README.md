# Secured Cloud Management Stack (SCM)
[![OpenStack](https://img.shields.io/badge/openstack-train-blue.svg?logo=openstack)](https://www.openstack.org/software/train/)
[![SGX](https://img.shields.io/badge/SGX-2.15.1-blue.svg)](https://github.com/intel/linux-sgx/tree/sgx_2.15.1)
[![TDX](https://img.shields.io/badge/TDX-1.5-blue.svg)](https://github.com/intel/tdx-tools/tree/tdx-1.5)
[![License](https://img.shields.io/badge/License-Apache%202.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview
Secured Cloud Management Stack aims to enable confidential computing from infrastructure level, provide chip-level data protection capability, and enhance security for cloud computing platform. With SCM, users could make the applications run in a secured virtual machine (VM) or bare metal (BM) environment which are protected by [Intel® Software Guard Extensions (SGX)](https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html) and [Intel® Trust Domain Extensions (TDX)](https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/documentation.html). And SCM could be applied widely in on-premise cloud and hybrid cloud owe to its excellent protection capability and flexibility. All modifications are made in patch format.

SCM provides automative deployment scripts to help users to quickly build the whole Cloud Software Stack and create SGX/TDX instances for practice. 

### Intel® Software Guard Extensions (SGX)
SGX as a key [Trusted Execution Environment (TEE)](https://en.wikipedia.org/wiki/Trusted_execution_environment) technology, is enabled in our current version. We know typical security measures may assist data at rest and in transit, but often fall short of protecting data while it is actively used in memory. Intel SGX helps protect data in use via application isolation technology. SGX offers hardware-based memory encryption that isolates code and data of specific application in memory. SGX allows user-level code to allocate private regions of memory, called enclaves, which are designed to be protected from processes running at higher privilege levels. 	

### Intel® Trust Domain Extensions (TDX)
Intel&reg; Trust Domain Extensions (TDX) refers to an Intel technology that extends Virtual Machine Extensions(VMX) and Multi-Key Total Memory Encryption(MK-TME) with a new kind of virtual machine guest called a Trust Domain(TD). A TD runs in a CPU mode that protects the confidentiality of its memory contents and its CPU state from any other software, including the hosting Virtual Machine Monitor (VMM). Please get more details from _[TDX White Papers and Specifications](https://github.com/intel/tdx-tools/wiki/API-&-Specifications)_

### Usage
[OpenStack](https://opendev.org/openstack) as a very inflenced open source cloud computing platform, is adopted as IaaS foundation in SCM with its [Train](https://www.openstack.org/software/train/) release. SCM makes modifications to different OpenStack components to achieve the SGX/TDX enablement in different dimensions and capabilities.

[Kubernetes](https://kubernetes.io/) also known as K8s, is an open-source system for automating deployment, scaling, and management of containerized applications. SCM consolidate the [Intel-device-plugin](https://github.com/intel/intel-device-plugins-for-kubernetes) and [node feature discovery](https://github.com/kubernetes-sigs/node-feature-discovery) to enable SGX in kubernetes. 

## Release
Currently, our SCM solution update to 3.0 release. Below table shows the cotents for each release.
| Release | Stack | Features |
| :- | :- | :- |
| [v1.0](scm1.0/) | OpenStack (train) | - Automatic SGX capability inspection and SGX nodes discovery;<br>- SGX capability enablement in OpenStack;<br>- SGX VM and BM lifecycle management;<br>- SGX EPC resource management. |
| [v2.0](./scm2.0/) | Kubernetes (v1.23.10)| - Automatic SGX capability inspection and SGX nodes discovery;<br>- SGX capability enablement in Kubernetes;<br>- SGX Pod lifecycle management;<br>- SGX EPC resource management. |
| [v3.0](./scm3.0/) | OpenStack (train) | - Automatic TDX nodes discovery;<br>- TDX/SGX capability enablement in the same OpenStack platform;<br>- TDVM guest image customization;<br>- TDVM instances lifecycle management. |


## How to Contribute to Our Stack

Customized development of OpenStack component based on a specified branch or tag
is submitted to this repo in the form of patch.
The whole development process is as follows.

1. Clone this repo.

2. Clone OpenStack component and check out to the specified branch or tag.

3. Apply component's patch in this repo by `git am <patch-file>` if it exists.

4. Complete development.

5. Format new patch by `git format-patch -<num> --stdout > <patch-file>`.

    *Note: num is the number of commits which contains origin patch's commits and new commits.*

6. Override component's patch in this repo with newly generated patch.

7. Create pull request and submit

## References
[SGX Documents](https://www.intel.com/content/www/us/en/products/docs/accelerator-engines/software-guard-extensions.html)
[TDX Documents](https://cczoo.readthedocs.io/en/latest/TEE/TDX/inteltdx.html)
[tdx-tools](https://github.com/intel/tdx-tools/tree/tdx-1.5)

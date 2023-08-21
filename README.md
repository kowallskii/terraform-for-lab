# TFGEN (Please use python-tfgen for generate more than 10 instances)

not-tfgen is the basic way to generate terraform HCL for libvirt provider. The real TFGEN is on-going.

### Update (Terraform 13!)
Guide update provider binary: https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/docs/migration-13.md

#### New feature:
* Interface without IP Address
```txt
[VMn]
IFACE_NETWORK2: 10.10.20.0
IFACE_IP2: none
```

### Core
- [x] Create main HCL file (main.tf)
  - [x] Nested Guest
  - [x] Graphics: VNC or Spice
  - [x] Dynamic multi disk drives
- [x] Create Cloudinit
  - [x] User: student & instructor
- [x] Create Network Config
  - [x] Dynamic multi interface

### TFGEN Guide

For example you want to create 2 VM(s) with following specification:

| VM Name | OS | vCPU(s) | Nested | RAM | Storage | NIC | Console | Inject Public Key |
|-|-|-|-|-|-|-|-|-|
| demo-tfgen1 | template-ubuntu1804.img | 2 | n | 4G | vda: 10G<br>vdb: 10G<br>vdc: 5G | ens3: 10.10.110.10/24 | spice | root@btechserver<br>ops@ops-laptop |
| demo-tfgen2 | template-centos8.qcow2 | 4 | y | 8G | vda: 50G | eth0: 10.10.110.20/24<br>eth1: 10.10.120.20/24 | vnc | root@btechserver<br>ops@ops-laptop |

You will need to create environment file like following example:

demo-env.txt
```txt
[LAB]
PUBKEY1: ssh-rsa example root@btechserver
PUBKEY2: ssh-rsa example ops@ops-laptop

[VM1]
NAME: demo-tfgen1
OS: template-ubuntu1804.img
NESTED: n
VCPUS: 2
MEMORY: 4G
DISK1: 10G
DISK2: 10G
DISK3: 5G
IFACE_NETWORK1: 10.10.110.0
IFACE_IP1: 10.10.110.10
CONSOLE: spice

[VM2]
NAME: demo-tfgen2
OS: template-centos8.qcow2
NESTED: y
VCPUS: 4
MEMORY: 8G
DISK1: 50G
IFACE_NETWORK1: 10.10.110.0
IFACE_IP1: 10.10.110.20
IFACE_NETWORK2: 10.10.120.0
IFACE_IP2: 10.10.120.20
CONSOLE: vnc
```

Generate Terraform files based on your environment file
```bash
# not-tfgen.sh <new_tf_dir> <env_file>

not-tfgen.sh demo-dir demo-env.txt
```

Now you are ready to create the VM
```bash
cd demo-dir

terraform init

terraform apply -auto-approve
```

### Explanation
Note: Only works on btech lab

### [LAB] Section
- PUBKEYn: Public Key that will be injected to the VM

### [VMn] Section
- NAME: domain name shown in virsh list
- OS: Cloud image name on pool storage (virsh vol-list isos)
- NESTED: y | n . Enable nested
- VCPUS: vCPU(s)
- MEMORY: nG. n is integer, only support Gigabyte Unit
- DISKn: nG. n is integer, only support Gigabyte Unit
- IFACE_NETWORKn: Network Address used by guest
- IFACE_IPn: IP Address used by guest
- CONSOLE: spice | vnc. Select console

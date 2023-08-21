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

# TUTOR GAMPANG
1. Install  "Virtualization Host" KVM

```jsx
sudo apt -y install bridge-utils cpu-checker libvirt-clients libvirt-daemon qemu qemu-kvm qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils mkisofs gawk
```

1. Enable nested virtualization kernel module

```jsx
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel nested=1
cat <<EOF >> /etc/modprobe.d/kvm.conf
options kvm-intel nested=1
EOF

sudo modprobe -r kvm_amd
sudo modprobe kvm_amd nested=1
cat <<EOF >> /etc/modprobe.d/kvm.conf
options kvm_amd nested=1
EOF
```

1. Start and enable libvirt

```jsx
systemctl enable --now libvirtd
```

1. Setup Terraform

```jsx
wget https://releases.hashicorp.com/terraform/0.13.7/terraform_0.13.7_linux_amd64.zip
apt install unzip -y
unzip terraform_0.13.7_linux_amd64.zip
mv terraform /usr/local/bin
terraform -v
```

1. Download tfgen

```jsx
git clone https://go.btech.id/arya/tfgen.git
atau
git clone https://github.com/anggakg/tfgen.git
sed -i -r 's/machine=*/machine="pc-i440fx-focal"/' tfgen/functionlib/gentemplate.sh
sed -i -r 's/machine=*/machine="pc-i440fx-jammy-hpb"/' tfgen/functionlib/gentemplate.sh
```

1. Setup libvirt provider

```jsx
mkdir -p ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
mv tfgen/provider/terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
```

1. buat file xml

```jsx
<network>
<name>net-10.10.10</name>
<forward mode='route'/>
<bridge name='virbr10' stp='on' delay='0'/>
<domain name='network'/>
<ip address='10.10.10.1' netmask='255.255.255.0'>
</ip>
</network>

virsh net-define network.xml
virsh net-start net-10.10.10
virsh net-autostart net-10.10.10
```

1. Buat Network

```jsx
for i in {236..239}; do virsh net-define 172.18.$i.xml && virsh net-autostart net-172.18.$i && virsh net-start net-172.18.$i; done
```

1. Setup storage pool

```jsx
mkdir -p /data/isos
mkdir /data/vms
virsh pool-define-as vms dir - - - - "/data/vms"
virsh pool-define-as isos dir - - - - "/data/isos"
virsh pool-autostart vms
virsh pool-autostart isos
virsh pool-start vms
virsh pool-start isos

#Update list isos
cd /data/isos
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
mv focal-server-cloudimg-amd64.img ubuntu-focal.img
mv bionic-server-cloudimg-amd64.img ubuntu-bionic.img
mv jammy-server-cloudimg-amd64.img ubuntu-jammy.img
virsh pool-refresh isos
virsh vol-list isos
```

1. Fix error qemu

```jsx
sed -i -r 's/#security_driver.*/security_driver = "none"/' /etc/libvirt/qemu.conf
systemctl restart libvirtd
```

1. Add rule iptables

```jsx
sudo iptables -t nat -A POSTROUTING -j MASQUERADE -o ens4

#Add persistent iptables nat
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install iptables-persistent -y
```

1. Create password cloud img (optional)

```jsx
sudo apt install libguestfs-tools
virt-customize -a bionic-server-cloudimg-amd64.img --root-password password:<pass>
```

Example :

```jsx
[LAB]
PUBKEY1: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChfYC+4sq44qaZgQtQUQa7PohBNmgBhx71H4pRYjaTYeaj9nP5aLeaQYi/QBZDV4AHJveLA90KKvycUqju9uWWxLTjLHP5oNTHG+5BWAbvTsk+HDiDa3MeoakjiGD5CLDpBC92UYlumh/VOiMyGvrjY8HjQWQbFepfcGsLZbzza8ekX5tC/TipCM+MBBXkqjhOOZYciOvhU53kdxb4BDtlueE3U56MtCtgnQYWoZRocosw3Z0ZOtE8YeaI38fchblUfHRY8ZXXVq5Ta/mWSMTmZsyXqspw9zckvrDtvL4FyXDs3BvxPcFbSMKEMBmxdKOusuLwLnM7P+bMAil+kppE9K7pie4qdvziYe/LPJjmciqKdyjN242VsYRpRgQfej3qJKyT1PgMj9N2ts2tthkf0LsZZe1gm+4YhLnEEa/MZv5jZVrNuqBUZixkywzJQUt6oemIKg7a2vPHGgxd1p6KbLIiQo7iTPWT+PFAAS1nbMlmwuA5YCYdn7xX3DzqCeU= root@maas-2

[VM1]
NAME: ops
OS: ubuntu-bionic.img
NESTED: y
VCPUS: 8
MEMORY: 16G
DISK1: 100G
IFACE_NETWORK1: 10.10.10.0
IFACE_IP1: 10.10.10.10
CONSOLE: vnc
```

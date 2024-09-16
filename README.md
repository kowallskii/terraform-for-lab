# Setup KVM for Homelab
Install  "Virtualization Host" KVM
```bash
sudo apt -y install bridge-utils cpu-checker libvirt-clients libvirt-daemon qemu qemu-kvm qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils mkisofs gawk
```
Enable nested virtualization kernel module
```bash
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
Start and enable libvirt
```bash
systemctl enable --now libvirtd
```
Setup Terraform 
```bash
wget https://releases.hashicorp.com/terraform/0.13.7/terraform_0.13.7_linux_amd64.zip
apt install unzip -y
unzip terraform_0.13.7_linux_amd64.zip
mv terraform /usr/local/bin
terraform -v
```
Download Tfgen
```bash
git clone https://github.com/maulanamalikjb147/terraform-for-lab.git
sed -i -r 's/machine=*/machine="pc-i440fx-focal"/' tfgen/functionlib/gentemplate.sh
```
Atau sesuaikan dengan os kalian yang di bagian sini , contoh di atas saya pake ubuntu focal . kalo untuk jammy ini ```pc-i440fx-jammy-hpb```

![image](https://github.com/maulanamalikjb147/terraform-for-lab/assets/108875877/6dcc33ad-c6a0-4495-b9fa-f449852475dc)


Setup libvirt provider
```
mkdir -p ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
mv terraform-for-lab/provider/terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
```

buat file xml untuk network
 ```bash
nano net-10-10-10.xml
```bash
<network>
<name>net-10.10.10</name>
<forward mode='route'/>
<bridge name='virbr10' stp='on' delay='0'/>
<domain name='network'/>
<ip address='10.10.10.1' netmask='255.255.255.0'>
</ip>
</network>
```
Buat network dari xml tersebut
```bash
virsh net-define net-10-10-10.xml
virsh net-start net-10.10.10
virsh net-autostart net-10.10.10
```
Setup storage pool
```bash
mkdir -p /data/isos
mkdir /data/vms
virsh pool-define-as vms dir - - - - "/data/vms"
virsh pool-define-as isos dir - - - - "/data/isos"
virsh pool-autostart vms
virsh pool-autostart isos
virsh pool-start vms
virsh pool-start isos
```
Setup isos
```bash
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
mv focal-server-cloudimg-amd64.img ubuntu-focal.img
mv bionic-server-cloudimg-amd64.img ubuntu-bionic.img
mv jammy-server-cloudimg-amd64.img ubuntu-jammy.img
virsh pool-refresh isos
virsh vol-list isos
```
Apabila error fix qemu
```bash
sed -i -r 's/#security_driver.*/security_driver = "none"/' /etc/libvirt/qemu.conf
systemctl restart libvirtd
```
Add rule iptables
```bash
sudo iptables -t nat -A POSTROUTING -j MASQUERADE -o ens4

#Add persistent iptables nat
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install iptables-persistent -y
```
Create password cloud img (optional)
```bash
sudo apt install libguestfs-tools
virt-customize -a bionic-server-cloudimg-amd64.img --root-password password:<pass>
```
### Example template create instance
```bash
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
> Tinggal Sesuaikan saja pubkey nya pakai pubkey baremetal

### How to 
Create Volume qemu
```bash
./not-tfgen.sh example example.txt
```
Init KVM
```bash
terraform init example/
```
Create KVM
```bash
terraform apply example/
```
Verify KVM Running
```bash
virsh list
```

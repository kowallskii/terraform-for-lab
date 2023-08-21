generate_environment_example() {
cat<<'EOF' > ${ENV_FILE}
# Example
# [VM0-9]
# NAME: {string}
# OS: centos8-minimal {without file extention}
# NESTED: {y or n}
# VCPUS: 4
# MEMORY: 16G
# DISK1: 10G
# DISK2: 20G {Additional Disk}
# IFACE_NETWORK1: 10.10.1X.0
# IFACE_IP1: 10.10.1X.10 
# IFACE_NETWORK2: 10.20.1X.0 {Additional Interface}
# IFACE_IP2: 10.20.1X.10 {Additional Interface}
# CONSOLE: vnc {vnc or spice}

[VM1]
NAME: studentX-example1
OS: centos8
NESTED: y
VCPUS: 8
MEMORY: 16G
DISK1: 10G
DISK2: 20G
IFACE_NETWORK1: 10.10.1X.0
IFACE_IP1: 10.10.1X.10
IFACE_NETWORK2: 10.20.1X.0
IFACE_IP2: 10.20.1X.10
CONSOLE: vnc

[VM2]
NAME: studentX-example2
OS: centos8
NESTED: y
VCPUS: 4
MEMORY: 8G
DISK1: 30G
DISK2: 40G
IFACE_NETWORK1: 10.10.1X.0
IFACE_IP1: 10.10.1X.20
IFACE_NETWORK2: 10.20.1X.0
IFACE_IP2: 10.20.1X.20
CONSOLE: vnc
EOF
}
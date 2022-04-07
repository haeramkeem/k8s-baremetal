#!/usr/bin/env bash

###################################################
#  PRE-CONFIG FOR INIT / JOIN KUBERNETES CLUSTER  #
###################################################

# Kubernetes requires the disabling of the partition swapping
#   swapoff -a to disable swapping
swapoff -a
#   sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+\s+swap\s+.+)/#\1/' /etc/fstab

# Use iptables and br_netfilter kernel module for IPv4 & IPv6 routing table
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter

# Configure Docker to use systemd as Cgroup driver
mkdir -pv /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
    "exec-opts": [ "native.cgroupdriver=systemd" ],
    "log-driver": "json-file",
    "log-opts": { "max-size": "100m" },
    "storage-driver": "overlay2",
    "storage-opts": [ "overlay2.override_kernel_check=true" ]
}
EOF



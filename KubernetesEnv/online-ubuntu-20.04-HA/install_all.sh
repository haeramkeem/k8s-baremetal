#!/bin/bash

###############
#  VARIABLES  #
###############
MASTERS=3
WORKERS=1
MASTER_IPBASE="192.168.1.10"
WORKER_IPBASE="192.168.1.20"

#########################
#  BASIC CONFIGURATION  #
#########################

# Install prerequisites
apt-get update
apt-get install -y git vim net-tools

# vim configuration 
echo 'alias vi=vim' >> /etc/profile
rm -rf ~/.vimrc
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc

# Set local DNS - this will make communication between nodes with hostname instead of IP
#   vagrant cannot parse and delivery shell code.
#       Master nodes ($1)
for (( i=1; i<=$MASTERS; i++  )); do echo "$MASTER_IPBASE$i k8s-m$i" >> /etc/hosts; done
#       Worker nodes ($2)
for (( i=1; i<=$WORKERS; i++  )); do echo "$WORKER_IPBASE$i k8s-w$i" >> /etc/hosts; done

# Config DNS server for external communication
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

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

################################
#  INSTALL RELATED REPOSITORY  #
################################

# Install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Install docker apt repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install kubernetes apt repo
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
https://apt.kubernetes.io/ \
kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Update apt
apt-get update

#######################
#  INSTALL DOCKER CE  #
#######################
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

########################
#  INSTALL KUBERNETES  #
########################
apt-get install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

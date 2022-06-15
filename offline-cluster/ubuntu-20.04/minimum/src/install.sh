#!/usr/bin/env bash

set -e

# Check superuser
if [[ $(whoami) != "root" ]]
then
    echo "Please run this script in superuser."
    echo "recommend: 'sudo su'"
    exit 1
fi

# Check node type
if [[ $1 != "--master" ]] && [[ $1 != "--worker" ]]
then
    echo "Please specify the node type: --master or --worker"
    exit 1
fi

WORKER_COUNT=${2:-2}
MASTER_IP=${3:-"192.168.1.101"}
WORKER_BASE=${4:-"192.168.1.20"}
TOKEN="123456.1234567890123456"
CIDR="172.16.0.0/16"
KUBE_VER="v1.23.5"

# Kubernetes requires the disabling of the partition swapping
#   swapoff -a to disable swapping
swapoff -a
#   sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+\s+swap\s+.+)/#\1/g' /etc/fstab

# Use iptables and br_netfilter kernel module for IPv4 & IPv6 routing table
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter
modprobe overlay
sysctl --system

# Set local DNS - this will make communication between nodes with hostname instead of IP
echo "$MASTER_IP k8s-m1" >> /etc/hosts
for (( i=1; i<=$WORKER_COUNT; i++  ))
do
    echo "$WORKER_BASE$i k8s-w$i" >> /etc/hosts
done

# Install Docker
dpkg -i ./debs/docker/*.deb
rm -rf ./debs/docker # Remove installation files 
systemctl enable --now docker.service

#   Configure cgroup driver
mkdir -pv /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

#   installing docker with .deb automatically starts the docker
#       thus, reloading docker after write a daemon.json file is required
#       the command `systemctl enable --now docker.service` would not load this configuration
systemctl daemon-reload
systemctl restart docker

# Load all images
for f in $(ls ./images/*.tar); do
    docker load < $f
    rm -rf $f # Remove image files
done

# Install Kubernetes
dpkg -i ./debs/k8s/*.deb
rm -rf ./debs/k8s
systemctl enable --now kubelet

# config for master node only
if [[ $1 = "--master" ]]
then
    # init kubernetes cluster
    kubeadm init\
        --token $TOKEN\
        --token-ttl 0 \
        --pod-network-cidr=$CIDR\
        --apiserver-advertise-address=$MASTER_IP \
        --kubernetes-version=$KUBE_VER

    # copy configuration
    mkdir -pv /root/.kube
    cp -irv /etc/kubernetes/admin.conf /root/.kube/config
    chown root:root /root/.kube/config

    mkdir -pv /home/blue/.kube
    cp -irv /etc/kubernetes/admin.conf /home/blue/.kube/config
    chown blue:blue /home/blue/.kube/config

    # config for kubernetes's network
    kubectl apply -f ./manifests/cni.yaml

fi

# config for worker nodes
if [[ $1 = "--worker" ]]
then
    # join kubernetes cluster
    kubeadm join\
        --token $TOKEN\
        --discovery-token-unsafe-skip-ca-verification $MASTER_IP:6443\

fi

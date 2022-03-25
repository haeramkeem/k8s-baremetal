#!/usr/bin/env bash

# Check node type
if [[ $1 = "" ]]
then
    echo "Please specify the node type: --master or --worker"
    exit 1
fi

# Kubernetes requires the disabling of the partition swapping
#   swapoff -a to disable swapping
swapoff -a
#   sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# Set SELinux in permissive mode (effectively disabling it)
#   SELinux means Security Enhanced Linux which is security-enhanced version of linux kernel
#       In RHEL/CentOS, SELinux is installed and running on 'enforce' mode by default
#       The 'enforce' mode rejects the insecured operations
#       And 'permissive' mode allows the insecured operations but leave the audit to the log
#       By 'disable' mode, u can disable the SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Use iptables and br_netfilter kernel module for IPv4 & IPv6 routing table
#   RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter

# Set local DNS - this will make communication between nodes with hostname instead of IP
#   vagrant cannot parse and delivery shell code.
echo "192.168.1.10 m-k8s" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done

# Install Docker
echo "----- BEGIN DOCKER INSTALL -----"
rpm -ivh --replacefiles --replacepkgs ./rpms/docker/*.rpm
systemctl enable --now docker.service
echo "Docker installed"

# Load all images
echo "----- LOAD IMAGES -----"
FILES="./images/*.tar"
for f in $FILES
do
    docker load < $f
done

# Install Kubernetes
echo "----- BEGIN K8S INSTALL -----"
rpm -ivh --replacefiles --replacepkgs ./rpms/k8s/*.rpm
echo "K8s installed"

# config for master node only
if [[ $1 = "--master" ]]
then
    # init kubernetes cluster
    kubeadm init\
        --token 123456.1234567890123456\
        --token-ttl 0 \
        --pod-network-cidr=172.16.0.0/16\
        --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

    # copy configuration
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    # config for kubernetes's network (Calico)
    kubectl apply -f ./manifests/calico.yaml
fi

# config for worker nodes
if [[ $1 = "--worker" ]]
then
    # join kubernetes cluster
    kubeadm join\
        --token 123456.1234567890123456 \
        --discovery-token-unsafe-skip-ca-verification 192.168.1.10:6443
fi

#!/usr/bin/env bash

# Check node type
if [[ $1 != "--master" ]] && [[ $1 != "--worker" ]]
then
    echo "Please specify the node type: --master or --worker"
    exit 1
fi

# Kubernetes requires the disabling of the partition swapping
#   swapoff -a to disable swapping
swapoff -a
#   sed to comment the swap partition in /etc/fstab
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

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
MASTER_IP=$(grep "m1-k8s:" meta.yaml | awk '{print $2}')
echo "$MASTER_IP m1-k8s" >> /etc/hosts
for (( i=1; i<=$(grep "worker-count:" meta.yaml | awk '{print $2}'); i++  ))
do
    echo "192.168.2.10$i w$i-k8s" >> /etc/hosts
done

# Install Docker
echo "----- BEGIN DOCKER INSTALL -----"
dpkg -i ./debs/docker/*.deb
rm -rf ./debs/docker # Remove installation files 

#   Configure cgroup driver
mkdir /etc/docker
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
  ],
  "insecure-registries": [
    "$MASTER_IP:$REG_PORT"
  ]
}
EOF

systemctl enable --now docker.service
echo "Docker installed"

# Load all images
echo "----- LOAD IMAGES -----"
FILES="./images/*.tar"
for f in $FILES
do
    docker load < $f
    rm -rf $f # Remove image files
done

# Install Kubernetes
echo "----- BEGIN K8S INSTALL -----"
dpkg -i ./debs/k8s/*.deb
rm -rf ./debs/k8s
systemctl enable --now kubelet
echo "K8s installed"

TOKEN=$(grep "token:" meta.yaml | awk '{print $2}')

# config for master node only
if [[ $1 = "--master" ]]
then
    # firewall configuration
    ufw enable
    ufw allow 6443,2379,2380,10250,10251,10252 proto tcp
    ufw status

    # init kubernetes cluster
    kubeadm init\
        --token $TOKEN\
        --token-ttl 0 \
        --pod-network-cidr=$(grep "cidr:" meta.yaml | awk '{print $2}')\
        --apiserver-advertise-address=$MASTER_IP

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
    # firewall configuration
    ufw enable
    ufw allow 10250
    ufw allow 30000:32767 proto tcp
    ufw status

    # join kubernetes cluster
    kubeadm join\
        --token $TOKEN\
        --discovery-token-unsafe-skip-ca-verification $MASTER_IP:6443\
fi

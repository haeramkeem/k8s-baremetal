#!/bin/bash

set -e
WORKDIR=$(dirname $0)

# Setup local DNS
# - Master node config
MASTER_HOST_PREFIX="k8s-m"
MASTER_IP_PREFIX="192.168.1.10"
MASTER_CNT="1"
for i in $(seq 1 $MASTER_CNT); do
    sudo tee -a /etc/hosts <<< "$MASTER_IP_PREFIX$i $MASTER_HOST_PREFIX$i"
done
# - Worker node config
WORKER_HOST_PREFIX="k8s-w"
WORKER_IP_PREFIX="192.168.1.20"
WORKER_CNT="3"
for i in $(seq 1 $WORKER_CNT); do
    sudo tee -a /etc/hosts <<< "$WORKER_IP_PREFIX$i $WORKER_HOST_PREFIX$i"
done

# Install all(containerd, kubelet, kubectl, and kubeadm)
# - Sort uninstalled
mkdir -pv $WORKDIR/rpms/installed_pkgs

for rpm_file in $(ls $WORKDIR/rpms/*.rpm); do
    rpm -q $(rpm -qp $rpm_file --nosignature) &> /dev/null \
    && mv $rpm_file $WORKDIR/rpms/installed_pkgs/
done

# - Move el8_6 packages to the installed_pkgs dir
#   to prevent installing duplicated el8_6 pkgs
mv $WORKDIR/rpms/*el8_6* $WORKDIR/rpms/installed_pkgs/

# - Install
sudo rpm -Uvh --force $WORKDIR/rpms/*.rpm

# -------------------------
# ContainerD
# -------------------------
# Configurations
# - Load 'overlay' and 'br_netfilter' for containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
# - Configurations for containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' \
        /etc/containerd/config.toml
sudo sed -i 's$sandbox_image = "k8s.gcr.io/pause:3.6"$sandbox_image = "k8s.gcr.io/pause:3.7"$g' \
        /etc/containerd/config.toml
# - Start containerd
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd
# Load images
for img in $(ls $WORKDIR/images/*.tar); do
    sudo ctr -n=k8s.io images import $img
    rm -rf $img
done

# -------------------------
# CRICTL
# -------------------------
# - Configurations for CRICTL
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
sudo crictl config image-endpoint unix:///var/run/containerd/containerd.sock

# -------------------------
# Kubernetes
# -------------------------
# Configurations
# - Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# - Kubernetes requires the disabling of the partition swapping
sudo swapoff -a
sudo sed -i.bak -r 's/(.+\s+swap\s+.+)/#\1/' /etc/fstab
# - Configure iptables for kubernetes-CRI
cat <<EOF | sudo tee -a /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# - Start kubelet
sudo sysctl --system
sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
sudo systemctl restart kubelet

# -------------------------
# Init cluster
# -------------------------
TOKEN="123456.1234567890123456"
CIDR="172.16.0.0/16"
# CONTROLPLANE scripts
if [[ $1 == "controlplane" ]]; then
    if ! `sudo ls /etc/resolv.conf &> /dev/null`; then
        echo "Initiating with kubeadm requires DNS server configuration: /etc/resolv.conf"
        exit 1
    fi

    # init kubernetes cluster
    sudo kubeadm init \
        --token $TOKEN \
        --token-ttl 0 \
        --pod-network-cidr=$CIDR \
        --apiserver-advertise-address=$MASTER_IP_PREFIX'1'

    # copy configuration
    sudo mkdir -pv /root/.kube
    sudo cp -irv /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config

    if [[ $(id -u) -ne 0 ]]; then
        mkdir -pv /home/$USER/.kube
        sudo cp -irv /etc/kubernetes/admin.conf /home/$USER/.kube/config
        sudo chown $USER:$USER /home/$USER/.kube/config
    fi

    # config for kubernetes's network
    kubectl apply -f ./manifests/cni.yaml
fi

# WORKER scripts
if [[ $1 == "worker" ]]; then
    # join kubernetes cluster
    kubeadm join \
        --token $TOKEN \
        --discovery-token-unsafe-skip-ca-verification $MASTER_IP_PREFIX'1:6443'
fi

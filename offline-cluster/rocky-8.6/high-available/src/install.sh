#!/bin/bash

set -e

# -------------------------
# Env
# -------------------------
# Working dir
WORKDIR=$(dirname $0)
# IP address & hostname
# - Self
NIC_NAME="enp0s3"
NODE_HOST=$(hostname)
NODE_IP=$(ip -4 addr show $NIC_NAME | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# - Masters
MASTER_HOST_PREFIX="k8s-m"
MASTER_IP_PREFIX="192.168.1.10"
MASTER_CNT="3"
# - Workers
WORKER_HOST_PREFIX="k8s-w"
WORKER_IP_PREFIX="192.168.1.20"
WORKER_CNT="3"
# Keepalived env
APISERVER_VIP="192.168.1.10"
APISERVER_DEST_PORT="26443"
# K8s env
TOKEN="123456.1234567890123456"
CIDR="172.16.0.0/16"

# -------------------------
# Options
# -------------------------
while getopts 'm:' opt; do
    case "$opt" in
        m) MODE="$OPTARG" ;;
        *) echo "Unknown option '$opt'"; exit 1 ;;
    esac
done

# -------------------------
# Setup local DNS
# -------------------------
# Self config
sudo tee -a /etc/hosts <<< "$NODE_IP $NODE_HOST"
# Master node config
for i in $(seq 1 $MASTER_CNT); do
    sudo tee -a /etc/hosts <<< "$MASTER_IP_PREFIX$i $MASTER_HOST_PREFIX$i"
done
# Worker node config
for i in $(seq 1 $WORKER_CNT); do
    sudo tee -a /etc/hosts <<< "$WORKER_IP_PREFIX$i $WORKER_HOST_PREFIX$i"
done

# -------------------------
# Install all(containerd, kubelet, kubectl, and kubeadm)
# -------------------------
# Sort uninstalled
function scan {
    local TARGET=$1
    mkdir -pv $TARGET/installed_pkgs

    for rpm_file in $(ls $TARGET/*.rpm); do
        rpm -q $(rpm -qp $rpm_file --nosignature) &> /dev/null \
        && mv $rpm_file $TARGET/installed_pkgs/
    done

    # - Move el8_6 packages to the installed_pkgs dir
    #   to prevent installing duplicated el8_6 pkgs
    mv $TARGET/*el8_6*.rpm $TARGET/installed_pkgs/
}
scan $WORKDIR/rpms

# Install
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
# End script when mode is not provided
[ -z "$MODE"] && exit 0

# '/etc/resolv.conf' must be present
if ! `sudo ls /etc/resolv.conf &> /dev/null`; then
    echo "Initiating with kubeadm requires DNS server configuration: /etc/resolv.conf"
    exit 1
fi

# Helper functions
function install_haproxy {
    sudo groupadd --gid 980 haproxy
    sudo useradd --gid 980 --uid 980 -r haproxy

    sudo mkdir -p /etc/haproxy
    sudo cp $WORKDIR/etc/haproxy.cfg.template /etc/haproxy/haproxy.cfg
    # sudo touch /etc/haproxy/domain2backend.map
    sudo chown -R haproxy:haproxy /etc/haproxy/

    sudo mkdir -p /var/lib/haproxy
    sudo touch /var/lib/haproxy/stats
    sudo chown -R haproxy:haproxy /var/lib/haproxy

    sudo cp $WORKDIR/bin/haproxy /usr/local/sbin/
    sudo cp $WORKDIR/etc/haproxy.service /lib/systemd/system/

    sudo sed -i "s/\${FE_PORT}/${APISERVER_DEST_PORT}/g" /etc/haproxy/haproxy.cfg
    sudo sed -i "s|\${HTTP_HEALTHCHECK_URLPATH}|/healthz|g" /etc/haproxy/haproxy.cfg

    for i in $(seq 1 $MASTER_CNT); do
        sudo tee -a /etc/haproxy/haproxy.cfg \
        <<< "    server $MASTER_HOST_PREFIX$i $MASTER_IP_PREFIX$i:6443 check"
    done

    sudo systemctl enable --now haproxy
    sudo systemctl restart haproxy
}

function install_keepalived {
    local TARGET=$1

    # Install Keepalived
    scan $WORKDIR/rpms/keepalived
    sudo rpm -Uvh --force $WORKDIR/rpms/keepalived/*.rpm

    # Generate apiserver checker
    sudo cp -irv $WORKDIR/etc/check_apiserver.sh /etc/keepalived/
    sudo sed -i "s/\${APISERVER_VIP}/${APISERVER_VIP}/g" /etc/keepalived/check_apiserver.sh
    sudo sed -i "s/\${APISERVER_DEST_PORT}/${APISERVER_DEST_PORT}/g" /etc/keepalived/check_apiserver.sh

    # Copy over keepalived conf
    sudo cp $WORKDIR/etc/keepalived.$MODE.conf /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${CHECK_SCRIPT_NAME}/check_apiserver/g" /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${NIC_NAME}/${NIC_NAME}/g" /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${VIP}/${APISERVER_VIP}/g" /etc/keepalived/keepalived.conf

    sudo systemctl enable --now keepalived
    sudo systemctl restart keepalived
}

function copy_kube_config {
    sudo mkdir -pv /root/.kube
    sudo cp -irv /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config

    if [[ $(id -u) -ne 0 ]]; then
        mkdir -pv /home/$USER/.kube
        sudo cp -irv /etc/kubernetes/admin.conf /home/$USER/.kube/config
        sudo chown $USER:$USER /home/$USER/.kube/config
    fi
}

# For real(active) master server ...
if [[ $MODE == "real" ]]; then
    # Allow firewall port
    sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
    sudo firewall-cmd --reload

    # Install HAProxy & Keepalived
    install_haproxy
    install_keepalived "real"

    # init kubernetes cluster
    sudo kubeadm init \
        --token $TOKEN \
        --token-ttl 0 \
        --pod-network-cidr $CIDR \
        --apiserver-advertise-address $APISERVER_VIP \
        --upload-certs \
        --control-plane-endpoint $APISERVER_VIP:$APISERVER_DEST_PORT

    # Copy kubectl config
    copy_kube_config

    # Install CNI plugin
    kubectl create -f $WORKDIR/manifests/cni.yaml
fi

# For sorry(standby) master server ...
if [[ $MODE == "sorry" ]]; then
    # Allow firewall port
    sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
    sudo firewall-cmd --reload

    # Install HAProxy & Keepalived
    install_haproxy
    install_keepalived "sorry"

    # init kubernetes cluster
    sudo kubeadm join \
        --token $TOKEN \
        --control-plane \
        --discovery-token-unsafe-skip-ca-verification \
        $APISERVER_VIP:$APISERVER_DEST_PORT

    # Copy kubectl config
    copy_kube_config
fi

# For normal master server ...
if [[ $MODE == "controlplane" ]]; then
    # Allow firewall port
    sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
    sudo firewall-cmd --reload

    # init kubernetes cluster
    sudo kubeadm join \
        --token $TOKEN \
        --control-plane \
        --discovery-token-unsafe-skip-ca-verification \
        $APISERVER_VIP:$APISERVER_DEST_PORT

    # Copy kubectl config
    copy_kube_config
fi

# For worker ...
if [[ $MODE == "worker" ]]; then
    # Allow firewall port
    sudo firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
    sudo firewall-cmd --reload

    # Join kubernetes cluster
    sudo kubeadm join \
        --token $TOKEN \
        --discovery-token-unsafe-skip-ca-verification \
        $APISERVER_VIP:$APISERVER_DEST_PORT
fi

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
# K8s env
TOKEN="123456.1234567890123456"
POD_CIDR="172.16.0.0/16"
# kube-vip env
# - Common
APISERVER_VIP="192.168.1.10"
KUBE_VIP_MODE="arp"
# - BGP Mode
KUBE_VIP_BGP_ROUTER_ID="192.168.1.2"
KUBE_VIP_BGP_LOCAL_AS=65000

# -------------------------
# Options
# -------------------------
while getopts 'm:c:k:' opt; do
    case "$opt" in
        m) echo "Initiation mode set to ${MODE:=$OPTARG}" ;;
        c) echo "Certificate key set to ${CERT_KEY:=$OPTARG}" ;;
        k) KUBE_VIP_MODE=$OPTARG; echo "Kube-vip mode set to $KUBE_VIP_MODE" ;;
        *) echo "Unknown option '$opt'"; exit 1 ;;
    esac
done

# -------------------------
# Install minimum cluster components
# -------------------------
$WORKDIR/k8s/install.sh -M $MASTER_CNT -W $WORKER_CNT

# Load images
for img in $(ls $WORKDIR/images/*.tar); do
    sudo ctr -n k8s.io images import $img
done

# Helper funcs
kube-vip() {
    local IMG=$(sudo crictl images | awk '/kube-vip/{print $1":"$2}')
    sudo ctr -n k8s.io run --rm --net-host $IMG vip /kube-vip $@
}

# ARP Mode Manifest
sudo mkdir -pv /etc/kubernetes/manifests

if [[ $KUBE_VIP_MODE == "arp" ]]; then
    kube-vip manifest pod \
        --interface $NIC_NAME \         # Primary NIC name
        --address $APISERVER_VIP \      # VIP
        --controlplane \                # Enable Kube-vip controlplane feature (VIP etc)
        --services \                    # Enable `LoadBalancer` K8s service type watcher
        --arp \                         # Use GARP to broadcast VIP-MAC
        --leaderElection \              # Elect leader for VIP / LB responsibility
        --enableLoadBalancer \          # Enable Kube-apiserver load balancing
        | sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' \
        | sudo tee /etc/kubernetes/manifests/kube-vip.yaml
fi

# BGP Mode Manifest
if [[ $KUBE_VIP_MODE == "bgp" ]]; then
    # Gen BGP peer string
    KUBE_VIP_BGP_PEERS=$MASTER_IP_PREFIX"1:$KUBE_VIP_BGP_LOCAL_AS::false"
    for i in $(seq 2 $MASTER_CNT); do
        KUBE_VIP_BGP_PEERS="$KUBE_VIP_BGP_PEERS,$MASTER_IP_PREFIX$i:$KUBE_VIP_BGP_LOCAL_AS::false"
    done

    # Gen manifest
    kube-vip manifest pod \
        --interface lo \
        --address $APISERVER_VIP \
        --controlplane \
        --services \
        --bgp \
        --localAS $KUBE_VIP_BGP_LOCAL_AS \
        --bgpRouterID $KUBE_VIP_BGP_ROUTER_ID \
        --bgppeers $KUBE_VIP_BGP_PEERS \
        | sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' \
        | sudo tee /etc/kubernetes/manifests/kube-vip.yaml
fi

case "$MODE" in
    init)
    # Allow firewall
    if `systemctl is-active --quiet firewalld`; then
        sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
        sudo firewall-cmd --reload
    fi

    # Initiate cluster
    sudo kubeadm init \
        --token $TOKEN \
        --token-ttl 0 \
        --pod-network-cidr $POD_CIDR \
        --upload-certs \
        --control-plane-endpoint $APISERVER_VIP:6443
        # --apiserver-advertise-address $APISERVER_VIP <-- It doesn't work for Kube-vip

    # Copy kubeconfig
    sudo mkdir /root/.kube
    sudo cp /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config # Double checking

    sudo mkdir $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Install CNI plugin
    kubectl create -f $WORKDIR/k8s/manifests/cni.yaml
    ;;

    controlplane)
    # Check certificate key
    if [[ -z $CERT_KEY ]]; then
        echo "Flag '-c' not provided. aborting."
        echo "Certificate key is required to join as control plane"
        exit 1
    fi

    # Allow firewall port
    if `systemctl is-active --quiet firewalld`; then
        sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
        sudo firewall-cmd --reload
    fi

    # init kubernetes cluster
    sudo kubeadm join \
        --token $TOKEN \
        --certificate-key $CERT_KEY \
        --control-plane \
        --discovery-token-unsafe-skip-ca-verification \
        $APISERVER_VIP:6443

    # Copy kubeconfig
    sudo mkdir /root/.kube
    sudo cp /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config # Double checking

    sudo mkdir $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ;;

    worker)
    # Allow firewall port
    if `systemctl is-active --quiet firewalld`; then
        sudo firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
        sudo firewall-cmd --reload
    fi

    # Join kubernetes cluster
    sudo kubeadm join \
        --token $TOKEN \
        --discovery-token-unsafe-skip-ca-verification \
        $APISERVER_VIP:6443
    ;;

    *) echo "Init flag '-m' not set. skipping initiation..."
esac

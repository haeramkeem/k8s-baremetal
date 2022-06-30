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
# Install minimum cluster components
# -------------------------
$WORKDIR/k8s/install.sh -m no-init -M $MASTER_CNT -W $WORKER_CNT

# -------------------------
# Init cluster
# -------------------------
# End script when mode is not provided
[ -z "$MODE"] && echo "Initiation mode flag '-m' not set'"; exit 0

# '/etc/resolv.conf' must be present
if ! `sudo ls /etc/resolv.conf &> /dev/null`; then
    echo >&2 "Initiating with kubeadm requires DNS server configuration: /etc/resolv.conf"
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
    # For root
    sudo mkdir -pv /root/.kube
    sudo cp -irv /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config

    # For non-root user
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

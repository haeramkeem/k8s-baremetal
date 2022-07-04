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
# HAProxy env
HAPROXY_STAT_PORT="8404"
HAPROXY_STAT_ADMIN_USERNAME="haproxy"
HAPROXY_STAT_ADMIN_PASSWORD="haproxy12345"
# K8s env
TOKEN="123456.1234567890123456"
CIDR="172.16.0.0/16"

# -------------------------
# Options
# -------------------------
while getopts 'm:c:' opt; do
    case "$opt" in
        m) echo "Initiation mode set to ${MODE:=$OPTARG}" ;;
        c) echo "Certificate key set to ${CERT_KEY:=$OPTARG}" ;;
        *) echo "Unknown option '$opt'"; exit 1 ;;
    esac
done

# -------------------------
# Install minimum cluster components
# -------------------------
$WORKDIR/k8s/install.sh -M $MASTER_CNT -W $WORKER_CNT

# -------------------------
# Init cluster
# -------------------------
# '/etc/resolv.conf' must be present
if ! `sudo ls /etc/resolv.conf &> /dev/null`; then
    echo >&2 "Initiating with kubeadm requires DNS server configuration: /etc/resolv.conf"
    exit 1
fi

# Helper functions
function install_haproxy {
    # Allow frontent port
    sudo firewall-cmd --permanent --add-port={$APISERVER_DEST_PORT, $HAPROXY_STAT_PORT}/tcp
    sudo firewall-cmd --reload

    # Add user for HAProxy
    sudo groupadd --gid 980 haproxy
    sudo useradd --gid 980 --uid 980 -r haproxy

    # Setup HAProxy config
    sudo mkdir -p /etc/haproxy
    sudo cp $WORKDIR/etc/haproxy.cfg.template /etc/haproxy/haproxy.cfg
    sudo chown -R haproxy:haproxy /etc/haproxy/

    # Setup HAProxy stats page
    sudo mkdir -p /var/lib/haproxy
    sudo touch /var/lib/haproxy/stats
    sudo chown -R haproxy:haproxy /var/lib/haproxy
    sudo sed -i "s/\${STAT_ADMIN_USERNAME}/${HAPROXY_STAT_ADMIN_USERNAME}/g" /etc/haproxy/haproxy.cfg
    sudo sed -i "s/\${STAT_ADMIN_PASSWORD}/${HAPROXY_STAT_ADMIN_PASSWORD}/g" /etc/haproxy/haproxy.cfg

    # Install & register systemd service
    sudo cp $WORKDIR/bin/haproxy /usr/local/sbin/
    sudo cp $WORKDIR/etc/haproxy.service /lib/systemd/system/

    # Configure
    sudo sed -i "s/\${FE_PORT}/${APISERVER_DEST_PORT}/g" /etc/haproxy/haproxy.cfg
    sudo sed -i "s|\${HTTP_HEALTHCHECK_URLPATH}|/healthz|g" /etc/haproxy/haproxy.cfg

    for i in $(seq 1 $MASTER_CNT); do
        sudo tee -a /etc/haproxy/haproxy.cfg \
        <<< "    server $MASTER_HOST_PREFIX$i $MASTER_IP_PREFIX$i:6443 check"
    done

    # Start systemd service
    sudo systemctl enable --now haproxy
    sudo systemctl restart haproxy
}

function install_keepalived {
    local TARGET=$1

    # Allow VRRP packet for keepalived
    sudo firewall-cmd --permanent --add-rich-rule='rule protocol value="vrrp" accept'
    sudo firewall-cmd --reload

    # Scan installed pkgs
    mkdir -pv $WORKDIR/rpms/keepalived/installed

    for rpm_file in $(ls $WORKDIR/rpms/keepalived/*.rpm); do
        rpm -q $(rpm -qp $rpm_file --nosignature) &> /dev/null \
        && mv $rpm_file $WORKDIR/rpms/keepalived/installed/
    done
    # - Move el8_6 packages to the installed_pkgs dir
    #   to prevent installing duplicated el8_6 pkgs
    mv $WORKDIR/rpms/keepalived/*el8_6*.rpm $WORKDIR/rpms/keepalived/installed/

    # Install
    sudo rpm -Uvh --force $WORKDIR/rpms/keepalived/*.rpm

    # Generate apiserver checker
    sudo cp -irv $WORKDIR/etc/check_apiserver.sh /etc/keepalived/
    sudo sed -i "s/\${APISERVER_VIP}/${APISERVER_VIP}/g" /etc/keepalived/check_apiserver.sh
    sudo sed -i "s/\${APISERVER_DEST_PORT}/${APISERVER_DEST_PORT}/g" /etc/keepalived/check_apiserver.sh

    # Copy over keepalived conf
    sudo cp $WORKDIR/etc/keepalived.$TARGET.conf /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${CHECK_SCRIPT_FNAME}/check_apiserver/g" /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${NIC_NAME}/${NIC_NAME}/g" /etc/keepalived/keepalived.conf
    sudo sed -i "s/\${VIP}/${APISERVER_VIP}/g" /etc/keepalived/keepalived.conf

    # Start systemd service
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

case "$MODE" in
    # For real(active) master server ...
    real)
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
        kubectl create -f $WORKDIR/k8s/manifests/cni.yaml
        ;;

    # For sorry(standby) master server ...
    sorry)
        # Check certificate key
        [ -z $CERT_KEY ] \
            && echo "Flag '-c' not provided. aborting." \
            && echo "Certificate key is required to join as master node" \
            && exit 1

        # Allow firewall port
        sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
        sudo firewall-cmd --reload

        # Install HAProxy & Keepalived
        install_haproxy
        install_keepalived "sorry"

        # init kubernetes cluster
        sudo kubeadm join \
            --token $TOKEN \
            --certificate-key $CERT_KEY \
            --control-plane \
            --discovery-token-unsafe-skip-ca-verification \
            $APISERVER_VIP:$APISERVER_DEST_PORT

        # Copy kubectl config
        copy_kube_config
        ;;

    # For normal master server ...
    controlplane)
        # Check certificate key
        [ -z $CERT_KEY ] \
            && echo "Flag '-c' not provided. aborting." \
            && echo "Certificate key is required to join as master node" \
            && exit 1

        # Allow firewall port
        sudo firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
        sudo firewall-cmd --reload

        # init kubernetes cluster
        sudo kubeadm join \
            --token $TOKEN \
            --certificate-key $CERT_KEY \
            --control-plane \
            --discovery-token-unsafe-skip-ca-verification \
            $APISERVER_VIP:$APISERVER_DEST_PORT

        # Copy kubectl config
        copy_kube_config
        ;;

    # For worker ...
    worker)
        # Allow firewall port
        sudo firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
        sudo firewall-cmd --reload

        # Join kubernetes cluster
        sudo kubeadm join \
            --token $TOKEN \
            --discovery-token-unsafe-skip-ca-verification \
            $APISERVER_VIP:$APISERVER_DEST_PORT
        ;;

    *) echo "Init flag '-m' not set. skipping initiation..."
esac

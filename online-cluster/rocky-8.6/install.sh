#!/bin/bash

# Install containerd, kube
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/kube/rhel8.sh)

TOKEN="123456.0123456789123456"
MODE=$1
MASTER_IP=$2

# Master
if [[ $MODE == "master" ]]; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/kubectl/rhel8.sh)

    if `systemctl is-active --quiet firewalld`; then
        firewall-cmd --permanent --add-port={179,6443,2379,2380,10250,10257,10259}/tcp
        firewall-cmd --reload
    fi

    kubeadm init \
        --token $TOKEN \
        --token-ttl 0 \
        --pod-network-cidr 172.16.0.0/16 \
        --apiserver-advertise-address $MASTER_IP

    mkdir -pv /root/.kube
    cp -irv /etc/kubernetes/admin.conf /root/.kube/config
    chown root:root /root/.kube/config

    # this is for vagrant user
    mkdir -pv /home/vagrant/.kube
    cp -irv /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown vagrant:vagrant /home/vagrant/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml
fi

# Worker
if [[ $MODE == "worker" ]]; then
    if `systemctl is-active --quiet firewalld`; then
        firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
        firewall-cmd --reload
    fi

    kubeadm join \
        --token $TOKEN \
        --discovery-token-unsafe-skip-ca-verification \
        $MASTER_IP:6443
fi

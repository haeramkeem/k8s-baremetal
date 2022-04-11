#!/usr/bin/env bash

# init kubernetes 
kubeadm init \
    --token 123456.1234567890123456 \
    --token-ttl 0 \
    --pod-network-cidr=172.16.0.0/16 \
    --apiserver-advertise-address=192.168.1.101 \
    --upload-certs \
    --control-plane-endpoint "192.168.1.101:26443"

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
kubectl apply -f \
https://projectcalico.docs.tigera.io/manifests/calico.yaml

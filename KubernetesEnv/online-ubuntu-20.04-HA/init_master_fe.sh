#!/bin/bash

###############
#  VARIABLES  #
###############

POD_CIDR="172.16.0.0/16"
CLUSTER_TOK="123456.1234567890123456"
# Get current node's IP
#   Ref: https://stackoverflow.com/a/26694162
LB_ENDPOINT_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
LB_ENDPOINT_PORT=26443

#####################
#  INSTALL HAPROXY  #
#####################

# Install latest stable version of HAProxy
apt-get install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.5 -y
apt-get update
apt-get install haproxy -y

# Overwrite HAProxy settings
cp ./haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy

#####################
#  INIT KUBERNETES  #
#####################

# Join cluster using `init_output.log`
kubeadm init \
    --token $CLUSTER_TOK \
    --token-ttl 0 \
    --pod-network-cidr=$POD_CIDR \
    --apiserver-advertise-address=$LB_ENDPOINT_IP \
    --upload-certs \
    --control-plane-endpoint "$LB_ENDPOINT_IP:$LB_ENDPOINT_PORT" &> \
    init_output.log

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml

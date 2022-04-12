#!/bin/bash

###############
#  VARIABLES  #
###############

POD_CIDR="172.16.0.0/16"
# Get current node's IP
#   Ref: https://stackoverflow.com/a/26694162
LB_ENDPOINT_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
LB_ENDPOINT_PORT=26443
CERT_KEY=$(kubeadm certs certificate-key)

#####################
#  INSTALL HAPROXY  #
#####################

# Install latest stable version of HAProxy
apt-get install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.5 -y
apt-get update
apt-get install haproxy -y

# Overwrite HAProxy settings
rm -rf /etc/haproxy/haproxy.cfg
curl https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/KubernetesEnv/online-ubuntu-20.04-HA/haproxy.cfg -o /etc/haproxy/haproxy.cfg
systemctl restart haproxy

#####################
#  INIT KUBERNETES  #
#####################

# Join cluster using `init_output.log`
#   Generated token is automatically deleted after 1s
kubeadm init \
    --certificate-key $CERT_KEY \
    --token-ttl "1s" \
    --pod-network-cidr $POD_CIDR \
    --apiserver-advertise-address $LB_ENDPOINT_IP \
    --upload-certs \
    --control-plane-endpoint "$LB_ENDPOINT_IP:$LB_ENDPOINT_PORT"

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml

##########################
#  GENERATE JOIN SCRIPT  #
##########################

# Generate join script for worker
JOIN_STR=$(kubeadm token create --print-join-command)
cat <<EOF > join_worker.sh
#!bin/bash
$JOIN_STR
EOF

# Generate join script for master
cat <<EOF > join_master.sh
#!/bin/bash
$JOIN_STR--control-plane --certificate-key $CERT_KEY
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
EOF

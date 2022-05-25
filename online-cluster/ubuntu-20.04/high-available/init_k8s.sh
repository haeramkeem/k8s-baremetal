#!/bin/bash

###############
#  VARIABLES  #
###############

# Check variables
if [[ -v $1 ]]; then
    echo "Please set the cluster endpoint"
    echo "* Format: 'IP:PORT'"
    exit 1
fi

LB_ENDPOINT_IP=$(echo $1 | cut -d ':' -f 1)
LB_ENDPOINT_PORT=$(echo $1 | cut -d ':' -f 2)
POD_CIDR="172.16.0.0/16"
CERT_KEY=$(kubeadm certs certificate-key)

#####################
#  INIT KUBERNETES  #
#####################

# Initiate cluster
kubeadm init \
    --certificate-key $CERT_KEY \
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
#!/bin/bash
$JOIN_STR
EOF
chmod 744 join_worker.sh

# Generate join script for master
cat <<EOF > join_master.sh
#!/bin/bash
$JOIN_STR--control-plane --certificate-key $CERT_KEY
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
EOF
chmod 744 join_master.sh

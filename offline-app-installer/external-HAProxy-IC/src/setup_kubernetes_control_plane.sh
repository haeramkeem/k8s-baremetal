#!/bin/bash

NODE_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ROOT=$(dirname $0)

# Load images
for img in $(ls images/*.tar); do docker load < $img; rm -rf $img; done

# Uninstall existing calico
kubectl delete -f $ROOT/manifests/calico-no-op.yaml

# Install Calico
kubectl apply -f $ROOT/manifests/tigera-operator.yaml
kubectl apply -f $ROOT/manifests/calico-bgp-installation.yaml

# Install calicoctl
cp $ROOT/bin/calicoctl /usr/local/bin/
chmod +x /usr/local/bin/calicoctl
mkdir -pv /etc/calico
cp $ROOT/etc/calicoctl.cfg /etc/calico/

# Configure Calico for BGP peering
calicoctl apply -f $ROOT/manifests/calico-bgp-configuration.yaml

# Create ConfigMap for ingress controller
kubectl create configmap haproxy-kubernetes-ingress

# Set the --node-ip argument for kubelet
echo "KUBELET_EXTRA_ARGS=--node-ip=$NODE_IP" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

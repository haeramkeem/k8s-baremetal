#!/bin/bash

WORKDIR=$(dirname $0)

# COMMON scripts
for img in $(ls $WORKDIR/images/*.tar); do
    sudo ctr -n k8s.io images import $img
    rm -rf $img
done

# CONTROLPLANE scripts
if [[ $1 == "controlplane" ]]; then
    # Apply LB service CIDR config
    kubectl create -f $WORKDIR/manifests/configmap.yaml

    # Apply Kube-vip cloud controller
    kubectl create -f $WORKDIR/manifests/kube-vip-cloud-controller.yaml
fi

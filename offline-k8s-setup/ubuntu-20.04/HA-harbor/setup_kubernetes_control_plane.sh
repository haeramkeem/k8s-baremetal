#!/bin/bash

# Source: https://github.com/haeramkeem/sh-it/blob/main/func/load_img.sh
function load_img {
    local image_path=$1
    local image_registry=$2
    local is_push=$3

    for img_tar in $(ls $img_path/*.tar); do

        image=$(sudo docker load < $image_tar \
            | sed –nr "s/Loaded image: (.+)/\1/gp")
        echo "Docker image ${image} loaded"
        
        if [[ $imageRegi != "" ]]; then

            conv_img_name="$image_registry/$(awk -F/ '{print $NF}' <<< ${img_name})"
            sudo docker tag $image $conv_img_name
            echo "Docker image ${image} tagged to ${conv_img_name}"

            if [[ $is_push == "--push" ]]; then

                sudo docker push $conv_img_name
                echo "Docker image ${conv_img_name} pushed to ${image_registry}"

            fi

        fi

    done

}

NODE_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ROOT=$(dirname $0)

# Install Calico
load_img "$ROOT/images"
kubectl create -f $ROOT/manifests/tigera-operator.yaml
kubectl apply -f $ROOT/manifests/calico-bgp-installation.yaml

# Install calicoctl
chmod +x $ROOT/bin/calicoctl
cp $ROOT/bin/calicoctl /usr/local/bin/
mkdir /etc/calico
cp $ROOT/etc/calicoctl.cfg /etc/calico/

# Configure Calico for BGP peering
calicoctl apply -f $ROOT/manifests/calico-bgp-configuration.yaml

# Create ConfigMap for ingress controller
kubectl create configmap haproxy-kubernetes-ingress

# Set the --node-ip argument for kubelet
touch /etc/default/kubelet
echo "KUBELET_EXTRA_ARGS=--node-ip=$NODE_IP" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

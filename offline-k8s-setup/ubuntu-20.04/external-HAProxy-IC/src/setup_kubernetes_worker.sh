#!/bin/bash

ROOT=$(dirname $0)
NODE_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

for img in $(ls images/*.tar); do docker load < $img; done

# Set the --node-ip argument for kubelet
echo "KUBELET_EXTRA_ARGS=--node-ip=$NODE_IP" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

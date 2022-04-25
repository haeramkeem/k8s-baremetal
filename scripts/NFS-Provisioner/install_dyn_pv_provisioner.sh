#!/bin/bash

if ! `helm version &> /dev/null`; then
    echo "This script requires helm"
    echo "Installation aborted"
    exit 1
fi

if [[ $1 == "" || $2 == "" ]]; then
    echo "Please specify the NFS server IP and mounted path"
    echo "* Synopsis: ./script.sh \${NFS_SERVER_IP} \${MOUNT_PATH}"
    echo "Installation aborted"
    exit 1
fi

helm repo add nfs-subdir-external-provisioner \
     https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm repo update
helm install nfs-subdir-external-provisioner \
    nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=$1 \
    --set nfs.path=$2 \
    --set nfs.reclaimPolicy="Retain" \
    --set storageClass.reclaimPolicy="Retain" \
    --set storageClass.accessModes="ReadWriteMany"

echo ""
echo ""
echo "PV dyn provisioner is installed"
echo "* NFS Server IP: $1"
echo "* NFS Mount Path: $2"
echo "* See https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md#configuration for more information about configuration"
echo "* Use 'kubectl get storageclass' command to see generated storageClass"
echo "* Use name of the generated storageClass to generate PVC automatically in StatefulSet"

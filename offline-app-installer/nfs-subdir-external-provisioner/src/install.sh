#!/bin/bash

set -e

WORKDIR=$(dirname $0)
NFS_IP=${2:-"192.168.1.20"}
NFS_PATH=${3:-"/nfs_shared"}

# Load images
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# Install NFS common
dpkg -i $WORKDIR/debs/nfs-common/*.deb

# For controlplane
if [[ $1 == "controlplane" ]]; then
    if ! `helm version &> /dev/null`; then
        dpkg -i $WORKDIR/debs/helm/*.deb
    fi

    helm install nsep $WORKDIR/charts/nfs-subdir-external-provisioner.tgz -f \
    $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml \
    --set nfs.server=$NFS_IP \
    --set nfs.path=$NFS_PATH
fi

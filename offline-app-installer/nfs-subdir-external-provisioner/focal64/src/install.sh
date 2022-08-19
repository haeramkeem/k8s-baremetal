#!/bin/bash

set -e

WORKDIR=$(dirname $0)

# COMMON script
# Load images
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# Install NFS common
dpkg -i $WORKDIR/debs/nfs-common/*.deb

# CONTROLPLANE script
# Synopsis: ./install.sh controlplane ${NFS_IP} ${NFS_PATH}
if [[ $1 == "controlplane" ]]; then
    NFS_IP=${2:-"192.168.1.20"}
    NFS_PATH=${3:-"/nfs_shared"}

    if ! `helm version &> /dev/null`; then
        dpkg -i $WORKDIR/debs/helm/*.deb
    fi

    helm install nsep $WORKDIR/charts/nfs-subdir-external-provisioner.tgz -f \
    $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml \
    --set nfs.server=$NFS_IP \
    --set nfs.path=$NFS_PATH
fi

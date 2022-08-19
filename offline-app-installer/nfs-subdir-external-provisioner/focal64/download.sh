#!/bin/bash

# ENVs
STUFF="nfs-subdir-external-provisioner"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
NSEP_VER="4.0.16"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/debs
mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/etcs
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/values

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker/focal64.sh)
fi

if ! `helm version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/focal64.sh)
fi

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# Download Helm
dl_deb_pkg $WORKDIR/debs/helm <<< "helm"

# Download nfs-common
dl_deb_pkg $WORKDIR/debs/nfs-common <<< "nfs-common libevent-2.1-7"

# Add nfs-subdir-external-provisioner chart repository
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/nfs-subdir-external-provisioner.sh)

# Download chart
cmd="nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version $NSEP_VER"
helm pull $cmd
mv -v nfs-subdir-external-provisioner-$NSEP_VER.tgz \
    $WORKDIR/charts/nfs-subdir-external-provisioner.tgz

# Download values.yaml
curl -Lo $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml \
    https://raw.githubusercontent.com/haeramkeem/yammy/main/helm/values/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner.yaml

# Download required images
helm template $cmd \
    -f $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml \
    | get_img_list_from_yaml \
    | dl_oci_imgs $WORKDIR/images

# Download installation script
curl -Lo $WORKDIR/install.sh \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/nfs-subdir-external-provisioner/focal64/src/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

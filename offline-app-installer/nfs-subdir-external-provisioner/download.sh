#!/bin/bash

# ENVs
USR=${1:-"vagrant"}
STUFF="nfs-subdir-external-provisioner"
WORKDIR="/home/$USR/$STUFF"
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
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
fi

if ! `helm version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)
fi

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

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
curl -L \
    https://raw.githubusercontent.com/haeramkeem/yammy/main/helm-values/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner.yaml \
    -o $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml

# Download required images
helm template $cmd \
    -f $WORKDIR/values/nfs-subdir-external-provisioner.values.yaml \
    | save_img_from_yaml $WORKDIR/images

# Download installation script
curl -L \
    https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/nfs-subdir-external-provisioner/src/install.sh \
    -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 711 $WORKDIR/install.sh

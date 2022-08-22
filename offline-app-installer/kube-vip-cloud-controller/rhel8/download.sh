#!/bin/bash

# Offline-stuff online downloader
# Copyright (c) SaltWalks/Coworking 2022
# Source: https://github.com/haeramkeem/sh-it/tree/main/boilerplate/online-downloader.sh

# This boilerplate is to download all the required stuffs for adding something to the Kubernetes cluster
# Here's how to use:
# 1. Download this boilerplate
# 2. Fill out the scripts as you want
# 3. Run this on the online node (via Vagrant or something)
# 4. Copy the generated directory to the offline node (via SCP or something)
# 5. Run 'install.sh' file to install

# ENVs
STUFF="kube-vip-cloud-controller"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="v0.0.3"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/manifests

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker/rhel8.sh)
fi

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# FILL OUT THE 'AS YOU WANT's
# Download Manifest
curl -L \
    https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml \
    | sed 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' \
    | tee $WORKDIR/manifests/$STUFF.yaml

# Download image
cat $WORKDIR/manifests/$STUFF.yaml \
    | get_img_list_from_yaml \
    | dl_oci_imgs $WORKDIR/images

# COPY 'install.sh' CONTENT
curl -Lo $WORKDIR/manifests/configmap.yaml \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/kube-vip-cloud-controller/rhel8/src/sample-configmap.yaml

curl -Lo $WORKDIR/install.sh \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/kube-vip-cloud-controller/rhel8/src/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

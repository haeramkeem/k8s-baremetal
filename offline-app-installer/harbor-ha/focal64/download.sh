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
STUFF="harbor"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="1.9.1"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/debs
mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/values
mkdir -pv $WORKDIR/etcs

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker/focal64.sh)
fi

if ! `helm version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/focal64.sh)
fi

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# FILL OUT THE 'AS YOU WANT's
# download chart
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/harbor.sh)
helm pull harbor/harbor --version $VERSION
mv -v harbor-$VERSION.tgz $WORKDIR/charts/harbor.tgz

# download values
curl -Lo $WORKDIR/values/harbor.values.yaml \
    https://raw.githubusercontent.com/haeramkeem/yammy/main/helm/values/harbor/nodeport-tls-ha.values.yaml

# download images
helm template $WORKDIR/charts/harbor.tgz \
    --values $WORKDIR/values/harbor.values.yaml \
    | get_img_list_from_yaml \
    | dl_oci_imgs $WORKDIR/images

# COPY 'install.sh' CONTENT
curl -Lo $WORKDIR/install.sh \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/HA-harbor/focal64/src/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

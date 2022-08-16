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

# Install prerequisite
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/jq/rhel8.sh)

# ENVs
STUFF="kube-vip"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

# Load funcs
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/images

# Download minimum installation files
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/minimum/download.sh) "$WORKDIR"

# Download kube-vip
dl_oci-imgs $WORKDIR/images <<< "ghcr.io/kube-vip/kube-vip:$VERSION"

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/kube-vip/src/install.sh"
curl -Lo $WORKDIR/install.sh $INSTALL_SH_URL
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

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
STUFF="docker-registry"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="2"

# Working directories
mkdir -pv $WORKDIR
# mkdir -pv $WORKDIR/debs
# mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/images
# mkdir -pv $WORKDIR/charts
# mkdir -pv $WORKDIR/values
mkdir -pv $WORKDIR/etcs

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
fi

# if ! `helm version &> /dev/null`; then
#     bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)
# fi

# Import functions
# source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
# source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# FILL OUT THE 'AS YOU WANT's
docker pull registry:$VERSION
docker save registry:$VERSION > $WORKDIR/images/registry.tar

# COPY 'install.sh' CONTENT
SRC="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/docker-registry/src"
curl -L $SRC/tls.csr -o $WORKDIR/etcs/tls.csr
curl -L $SRC/install.sh -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

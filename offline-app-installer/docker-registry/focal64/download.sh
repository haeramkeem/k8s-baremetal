#!/bin/bash

# ENVs
STUFF="docker-registry"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="2"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/etcs

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker/focal64.sh)
fi

# Load funcs
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# FILL OUT THE 'AS YOU WANT's
dl_oci_imgs $WORKDIR/images <<< "docker.io/library/registry:$VERSION"

# COPY 'install.sh' CONTENT
SRC="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/docker-registry/focal64/src"
curl -L $SRC/tls.csr -o $WORKDIR/etcs/tls.csr
curl -L $SRC/install.sh -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

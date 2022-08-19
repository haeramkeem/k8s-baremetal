#!/bin/bash

# ENVs
STUFF=""
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION=""

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/debs
mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/values
mkdir -pv $WORKDIR/manifests
mkdir -pv $WORKDIR/etcs

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

# FILL OUT THE 'AS YOU WANT's

# COPY 'install.sh' CONTENT
INSTALL_SH_URL=""
curl -L $INSTALL_SH_URL -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

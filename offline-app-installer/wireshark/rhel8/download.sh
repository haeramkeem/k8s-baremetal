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
STUFF="wireshark"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="2.6.2" # YUM/DNF only provides this version

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms

# Import func
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_rpm_pkg.sh)

# FILL OUT THE 'AS YOU WANT's
dl_rpm_pkg $WORKDIR/rpms <<< "wireshark-$VERSION"

# COPY 'install.sh' CONTENT
curl -Lo $WORKDIR/install.sh \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/wireshark/rhel8/src/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

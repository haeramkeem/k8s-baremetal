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
STUFF="keepalived"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION=""

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms
mkdir -pv $WORKDIR/etcs

# Import func
source <(bash -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_rpm_pkg.sh)

# FILL OUT THE 'AS YOU WANT's
# Download Keepalived
dl_rpm_pkg $WORKDIR/rpms/keepalived <<< "keepalived$VERSION"

# Download keepalived.conf
curl -Lo $WORKDIR/etcs/keepalived.real.conf \
    https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/keepalived/keepalived.real.conf
curl -Lo $WORKDIR/etcs/keepalived.sorry.conf \
    https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/keepalived/keepalived.sorry.conf

# Download health check script
# COPY 'install.sh' CONTENT
SRC="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/keepalived/rhel8/src"
curl -Lo $WORKDIR/etcs/health_chk.sh $SRC/health_chk.sh
curl -Lo $WORKDIR/install.sh $SRC/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

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
STUFF="nfs"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="2.3.3"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms

# Install dependencies

# Import functions

# FILL OUT THE 'AS YOU WANT's
mkdir -pv $WORKDIR/rpms/nfs-utils
repotrack nfs-utils-$VERSION
mv *.rpm $WORKDIR/rpms/nfs-utils

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/rhel8/nfs/src/install.sh"
curl -L $INSTALL_SH_URL -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

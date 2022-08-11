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

# FILL OUT THE 'AS YOU WANT's
# Download Keepalived
mkdir -pv $WORKDIR/rpms/keepalived
cd $WORKDIR/rpms/keepalived
repotrack keepalived
cd $WORKDIR

# Download keepalived.conf
REAL_CONF_URL="https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/keepalived/keepalived.real.conf"
SRRY_CONF_URL="https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/keepalived/keepalived.sorry.conf"
curl -L $REAL_CONF_URL -o $WORKDIR/etcs/keepalived.real.conf
curl -L $SRRY_CONF_URL -o $WORKDIR/etcs/keepalived.sorry.conf

# Download health check script
HEALTH_SH_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/rhel8/keepalived/src/health_chk.sh"
curl -L $HEALTH_SH_URL -o $WORKDIR/etcs/health_chk.sh

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/rhel8/keepalived/src/install.sh"
curl -L $INSTALL_SH_URL -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

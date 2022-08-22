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
STUFF="ha-k8s"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION=${2:+"-$2"}

HAPROXY_VER_MAJOR="2.6"
HAPROXY_VER="$HAPROXY_VER_MAJOR.1"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms
mkdir -pv $WORKDIR/bin
mkdir -pv $WORKDIR/etc

# Load functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# Download minimum installation files
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/minimum/download.sh) "$WORKDIR"

# Build HAProxy binary
FNAME="haproxy-$HAPROXY_VER"
C_TARGET="linux-glibc"
# - Install prerequisites
dnf install -y pcre-devel zlib-devel openssl-devel systemd-devel
# - Download release
curl -LO http://www.haproxy.org/download/$HAPROXY_VER_MAJOR/src/$FNAME.tar.gz
tar -xzvf $FNAME.tar.gz
ROOT=$PWD; cd $FNAME
# - Build
make TARGET=$C_TARGET USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_SYSTEMD=1
mv haproxy $WORKDIR/bin/
# - Generate systemd service
cd ./admin/systemd
make
mv haproxy.service $WORKDIR/etc/
# - Cleanup
cd $ROOT
rm -rf $FNAME $FNAME.tar.gz
# - Download HAProxy config template
HAP_CONF_URL="https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/haproxy/haproxy.cfg.template"
curl -Lo $WORKDIR/etc/haproxy.cfg.template $HAP_CONF_URL

# Download Keepalived
# - Download pkg
mkdir -pv $WORKDIR/rpms/keepalived
repotrack keepalived
mv *.rpm $WORKDIR/rpms/keepalived/
# - Download keepalived config template
KA_CONF_URL="https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/keepalived/keepalived"
curl -Lo $WORKDIR/etc/keepalived.real.conf "$KA_CONF_URL.real.conf"
curl -Lo $WORKDIR/etc/keepalived.sorry.conf "$KA_CONF_URL.sorry.conf"
# - Download keepalived health checker
CHECK_APISERVER_URL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/high-available/src/check_apiserver.sh"
curl -Lo $WORKDIR/etc/check_apiserver.sh $CHECK_APISERVER_URL
sed -i 's/\r//g' $WORKDIR/etc/check_apiserver.sh
chmod 700 $WORKDIR/etc/check_apiserver.sh

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/high-available/src/install.sh"
curl -Lo $WORKDIR/install.sh $INSTALL_SH_URL
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

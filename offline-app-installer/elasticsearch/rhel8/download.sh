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
STUFF="elasticsearch"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="7.17.3"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/values
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/images

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker/rhel8.sh)
fi
# Install Helm for offline
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/rhel8/helm/download.sh) $WORKDIR

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# FILL OUT THE 'AS YOU WANT's
# Install Elasticsearch repository
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/elastic.sh)
# Download elasticsearch chart
helm pull elastic/elasticsearch --version $VERSION
mv elasticsearch-$VERSION.tgz $WORKDIR/charts/elasticsearch.tgz

# Download values
curl -Lo $WORKDIR/values/elasticsearch.yaml \
    https://raw.githubusercontent.com/haeramkeem/yammy/main/helm/values/elastic/elasticsearch/values.yaml

# Download images
helm template $WORKDIR/charts/elasticsearch.tgz \
    -f $WORKDIR/values/elasticsearch.yaml \
    | get_img_list_from_yaml \
    | dl_oci_imgs $WORKDIR/images

# COPY 'install.sh' CONTENT
curl -Lo $WORKDIR/install.sh \
    https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-app-installer/elasticsearch/rhel8/src/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

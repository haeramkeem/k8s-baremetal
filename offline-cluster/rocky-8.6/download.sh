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
STUFF="k8s"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION=${2:+"-$2"}

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/manifests

# Load functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# Install docker and kube stuff
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/rhel8/kube.sh)

# Download containerd and kube stuff
repotrack containerd kubelet$VERSION kubectl$VERSION kubeadm$VERSION --disableexcludes kubernetes
mv *.rpm $WORKDIR/rpms

# Download images
for img in $(kubeadm config images list); do
docker pull $img
docker save $img > $WORKDIR/images/$(awk -F/ '{print $NF}' <<< $img).tar
done

# download cni yaml
CNI_YAML="https://projectcalico.docs.tigera.io/manifests/calico.yaml"
curl -Lo $WORKDIR/manifests/cni.yaml $CNI_YAML

# download cni-related docker image
cat $WORKDIR/manifests/cni.yaml | save_img_from_yaml $WORKDIR/images

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-cluster/rocky-8.6/src/install.sh"
curl -L $INSTALL_SH_URL -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

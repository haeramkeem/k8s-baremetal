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
CNI_YAML="https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/rpms
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/manifests

# Load functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/get_img_list_from_yaml.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_oci_imgs.sh)

# Install docker and kube stuff
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/kube/rhel8.sh)

# Download containerd and kube stuff
repotrack containerd kubelet$VERSION kubectl$VERSION kubeadm$VERSION --disableexcludes kubernetes
mv *.rpm $WORKDIR/rpms

# Download images
kubeadm config images list \
    | dl_oci_imgs $WORKDIR/images

# download cni yaml
curl -Lo $WORKDIR/manifests/cni.yaml $CNI_YAML

# download cni-related docker image
cat $WORKDIR/manifests/cni.yaml \
    | get_img_list_from_yaml \
    | dl_oci_imgs $WORKDIR/images

# COPY 'install.sh' CONTENT
curl -L "https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/minimum/src/install.sh" \
    -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

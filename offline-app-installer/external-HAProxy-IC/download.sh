#!/bin/bash

set -e

# ENVs
SRC="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/external-HAProxy-IC/src"
ROOT="/home/vagrant"
X86_ARCH="x86_64"
AMD_ARCH="amd64"
OS_NAME="Linux"
OS_LOWERCASE="linux"

# Basic setup
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

#############
#  INGRESS  #
#############

ING_DIR="$ROOT/ingress"
HAPROXY_VER="2.5"
HAPROXY_IC_VER="1.7.10"

mkdir -pv $ING_DIR
mkdir -pv $ING_DIR/deb
mkdir -pv $ING_DIR/bin
mkdir -pv $ING_DIR/etc
apt-get update

# Download HAProxy
add-apt-repository -y ppa:vbernat/haproxy-${HAPROXY_VER}
apt-get update
dl_deb_pkg "${ING_DIR}/deb/haproxy" <<< "haproxy"

# Download the HAProxy Kubernetes Ingress Controller
TAR_NAME="haproxy-ingress-controller_${HAPROXY_IC_VER}_${OS_NAME}_${X86_ARCH}.tar.gz"
curl -LO \
    https://github.com/haproxytech/kubernetes-ingress/releases/download/v${HAPROXY_IC_VER}/${TAR_NAME}
tar -xzvf ${TAR_NAME} -C ${ING_DIR}/bin
rm -rf $TAR_NAME

# Copy the HAProxy Kubernetes Ingress Controller service
curl -L $SRC/haproxy-ingress.service -o ${ING_DIR}/etc/haproxy-ingress.service
curl -L $SRC/haproxy.cfg -o ${ING_DIR}/etc/haproxy.cfg

# Install Bird
add-apt-repository -y ppa:cz.nic-labs/bird
apt update
dl_deb_pkg "${ING_DIR}/deb/bird" <<< "bird"

# Copy over bird.conf
curl -L $SRC/bird.conf -o ${ING_DIR}/etc/bird.conf

# Copy over setup_ingress_controller.sh
curl -L $SRC/setup_ingress_controller.sh ${ING_DIR}/install.sh
chmod 700 ${ING_DIR}/install.sh

##################
#  CONTROLPLANE  #
##################

CTL_DIR="$ROOT/controlplane"
CAL_VER="3.23.1"

mkdir -pv $CTL_DIR
mkdir -pv $CTL_DIR/bin
mkdir -pv $CTL_DIR/etc
mkdir -pv $CTL_DIR/images
mkdir -pv $CTL_DIR/manifests

# Download calico release tgz
FNAME="release-v${CAL_VER}"
curl -LO \
    https://github.com/projectcalico/calico/releases/download/v${CAL_VER}/${FNAME}.tgz
tar -xzvf $FNAME.tgz

# Copy calico no-operator version
cp -v $FNAME/manifests/calico.yaml $CTL_DIR/manifests/calico-no-op.yaml

# Copy tigera-operator
cp -v $FNAME/manifests/tigera-operator.yaml $CTL_DIR/manifests/tigera-operator.yaml

# Save tigera-operator image
cat $CTL_DIR/manifests/tigera-operator.yaml | save_img_from_yaml $CTL_DIR/images

# Copy calicoctl
cp -v $FNAME/bin/calicoctl/calicoctl-${OS_LOWERCASE}-${AMD_ARCH} $CTL_DIR/bin/calicoctl

# Copy calico images
cp -v $FNAME/images/* $CTL_DIR/images/.

# Cleanup
rm -rf $FNAME*

# Copy over calico BGP installation
curl -L $SRC/calico-bgp-installation.yaml -o $CTL_DIR/manifests/calico-bgp-installation.yaml

# Copy over calico configuration
curl -L $SRC/calicoctl.cfg -o $CTL_DIR/etc/calicoctl.cfg

# Copy over Calico YAML for BGP peering
curl -L $SRC/calico-bgp-configuration.yaml -o $CTL_DIR/manifests/calico-bgp-configuration.yaml

# Copy over setup_kubernetes_controlplane.sh
curl -L $SRC/setup_kubernetes_control_plane.sh -o ${CTL_DIR}/install.sh
chmod 700 ${CTL_DIR}/install.sh

############
#  WORKER  #
############

WKR_DIR="$ROOT/worker"

mkdir -pv $WKR_DIR

# Copy images
cp -rv $CTL_DIR/images $WKR_DIR/images

# Copy over setup_kubernetes_worker.sh
curl -L $SRC/setup_kubernetes_worker.sh -o ${WKR_DIR}/install.sh
chmod 700 ${WKR_DIR}/install.sh

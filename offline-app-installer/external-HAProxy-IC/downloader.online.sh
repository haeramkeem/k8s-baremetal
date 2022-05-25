#!/bin/bash

set -e

# ENVs
SRC="/vagrant/src"
ROOT="/home/vagrant"
X86_ARCH="x86_64"
AMD_ARCH="amd64"
OS_NAME="Linux"
OS_LOWERCASE="linux"

# Basic setup
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# Remove CR
for file in $(ls ${SRC}/*); do
    sed -i 's/\r//g' $file
done

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
cp -v $SRC/haproxy-ingress.service ${ING_DIR}/etc/
cp -v $SRC/haproxy.cfg ${ING_DIR}/etc/

# Install Bird
add-apt-repository -y ppa:cz.nic-labs/bird
apt update
dl_deb_pkg "${ING_DIR}/deb/bird" <<< "bird"

# Copy over bird.conf
cp -v $SRC/bird.conf ${ING_DIR}/etc/bird.conf

# Copy over setup_ingress_controller.sh
cp -v $SRC/setup_ingress_controller.sh ${ING_DIR}/

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
cp -v $SRC/calico-bgp-installation.yaml $CTL_DIR/manifests/calico-bgp-installation.yaml

# Copy over calico configuration
cp -v $SRC/calicoctl.cfg $CTL_DIR/etc/calicoctl.cfg

# Copy over Calico YAML for BGP peering
cp -v $SRC/calico-bgp-configuration.yaml $CTL_DIR/manifests/calico-bgp-configuration.yaml

# Copy over setup_kubernetes_controlplane.sh
cp -v $SRC/setup_kubernetes_control_plane.sh ${CTL_DIR}/

############
#  WORKER  #
############

WKR_DIR="$ROOT/worker"

mkdir -pv $WKR_DIR

# Copy images
cp -rv $CTL_DIR/images $WKR_DIR/images

# Copy over setup_kubernetes_worker.sh
cp -v $SRC/setup_kubernetes_worker.sh ${WKR_DIR}/

#!/bin/bash

set -e

ROOT="/home/vagrant"
X86_ARCH="x86_64"
AMD_ARCH="amd64"
OS_NAME="Linux"

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
dl_deb_pkg "haproxy" "${ING_DIR}/deb/haproxy"

# Download the HAProxy Kubernetes Ingress Controller
TAR_NAME="haproxy-ingress-controller_${HAPROXY_IC_VER}_${OS_NAME}_${X86_ARCH}.tar.gz"
curl -LO \
    https://github.com/haproxytech/kubernetes-ingress/releases/download/v${HAPROXY_IC_VER}/${TAR_NAME}
tar -xzvf ${TAR_NAME} -C ${ING_DIR}/bin
rm -rf $TAR_NAME

# Download the HAProxy Kubernetes Ingress Controller service
curl -L \
    https://raw.githubusercontent.com/haproxytechblog/ingress-controller-external-example/master/haproxy-ingress.service \
    -o ${ING_DIR}/etc/haproxy-ingress.service

# Install Bird
add-apt-repository -y ppa:cz.nic-labs/bird
apt update
dl_deb_pkg "bird" "${ING_DIR}/deb/bird"

# Copy over bird.conf
curl -L \
    https://raw.githubusercontent.com/haproxytechblog/ingress-controller-external-example/master/bird.conf \
    -o ${ING_DIR}/etc/bird.conf

# Copy over setup_ingress_controller.sh
sed -i -e 's/\r$//g' /vagrant/setup_ingress_controller.sh
cp /vagrant/setup_ingress_controller.sh ${ING_DIR}/

##################
#  CONTROLPLANE  #
##################

CTL_DIR="$ROOT/controlplane"
CAL_VER="3.23.1"

mkdir -pv $CTL_DIR
mkdir -pv $CTL_DIR/deb
mkdir -pv $CTL_DIR/bin
mkdir -pv $CTL_DIR/etc
mkdir -pv $CTL_DIR/images
mkdir -pv $CTL_DIR/manifests

# Download Calico
curl -L \
    https://docs.projectcalico.org/manifests/tigera-operator.yaml \
    -o $CTL_DIR/manifests/tigera-operator.yaml

cat $CTL_DIR/manifests/tigera-operator.yaml | \
    save_img_from_yaml "${CTL_DIR}/images"

# Download calicoctl
curl -L \
    https://github.com/projectcalico/calico/releases/download/v${CAL_VER}/calicoctl-${OS_NAME}-${AMD_ARCH} \
    -o $CTL_DIR/bin/calicoctl

curl -L \
    https://raw.githubusercontent.com/haproxytechblog/ingress-controller-external-example/master/calicoctl.cfg \
    -o $CTL_DIR/etc/calicoctl.cfg

# Download Calico YAML for BGP peering
curl -L \
    https://raw.githubusercontent.com/haproxytechblog/ingress-controller-external-example/master/calico-installation.yaml \
    -o $CTL_DIR/manifests/calico-bgp-installation.yaml

curl -L \
    https://raw.githubusercontent.com/haproxytechblog/ingress-controller-external-example/master/calico-bgpconfiguration.yaml \
    -o $CTL_DIR/manifests/calico-bgp-configuration.yaml

# Copy over setup_kubernetes_controlplane.sh
sed -i -e 's/\r$//g' /vagrant/setup_kubernetes_control_plane.sh
cp /vagrant/setup_kubernetes_control_plane.sh ${CTL_DIR}/

############
#  WORKER  #
############

WKR_DIR="$ROOT/worker"

mkdir -pv $WKR_DIR
mkdir -pv $WKR_DIR/images

# Copy images
cp $CTL_DIR/images/* $WKR_DIR/images/.

# Copy over setup_kubernetes_worker.sh
sed -i -e 's/\r$//g' /vagrant/setup_kubernetes_worker.sh
cp /vagrant/setup_kubernetes_worker.sh ${WKR_DIR}/

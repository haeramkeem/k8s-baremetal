#!/bin/bash

# ENVs
STUFF="loki-stack"
INSTALLDIR=${1:-"$PWD"}
WORKDIR="$INSTALLDIR/$STUFF"
VERSION="2.6.5"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/debs
mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/values
mkdir -pv $WORKDIR/etcs

# Install dependencies
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
fi

if ! `helm version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)
fi

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# FILL OUT THE 'AS YOU WANT's
# download chart
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/grafana.sh)
helm pull grafana/loki-stack --version $VERSION
mv -v loki-stack-$VERSION.tgz $WORKDIR/charts/loki-stack.tgz

# download values
curl -L \
    https://raw.githubusercontent.com/haeramkeem/yammy/main/helm-values/grafana/loki-stack/values.yaml \
    -o $WORKDIR/values/loki-stack.values.yaml

# download images
helm template $WORKDIR/charts/loki-stack.tgz \
    --values $WORKDIR/values/loki-stack.values.yaml \
    | save_img_from_yaml $WORKDIR/images

# COPY 'install.sh' CONTENT
INSTALL_SH_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-app-installer/loki-stack/src/install.sh"
curl -L $INSTALL_SH_URL -o $WORKDIR/install.sh
sed -i 's/\r//g' $WORKDIR/install.sh
chmod 700 $WORKDIR/install.sh

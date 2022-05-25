#!/bin/bash

set -e

SETUP_DIR="/home/vagrant/setup"
X86_ARCH="x86_64"
AMD_ARCH="amd64"
OS_NAME="Linux"

# Import scripts
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# Install Docker
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)

# Install Helm
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)

# Add helm/bitnami repository
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/bitnami.sh)

# Add helm/harbor repository
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/harbor.sh)

# Chart version
PSQL_VER="9.0.12"
REDIS_VER="16.9.11"
HARBOR_VER="1.9.0"

# Chart values URL
PSQL_VALUES_URL="https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/app-install-manifests/helm-repos/bitnami/postgresql-ha/values.yaml"
REDIS_VALUES_URL="https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/app-install-manifests/helm-repos/bitnami/redis/ha.values.yaml"
HARBOR_VALUES_URL="https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/app-install-manifests/helm-repos/harbor/ingress-notls-ha.values.yaml"

# Destination path
mkdir -pv $SETUP_DIR
mkdir -pv $SETUP_DIR/debs
mkdir -pv $SETUP_DIR/charts
mkdir -pv $SETUP_DIR/values
mkdir -pv $SETUP_DIR/images

# Download helm
dl_deb_pkg $SETUP_DIR/deb/helm <<< "helm"

# Preparation function
function prepare_chart {
    local repo=$1
    local chart=$2
    local version=$3
    local cmd="$repo/$chart --version $version"

    helm pull $cmd
    mv -v $chart-$version.tgz $SETUP_DIR/charts/$chart.tgz
    helm template $cmd --values $SETUP_DIR/values/$chart.values.yaml \
        | save_img_from_yaml $SETUP_DIR/images
}

# Prepare PostgreSQL HA chart
curl -L $PSQL_VALUES_URL -o $SETUP_DIR/values/postgresql-ha.values.yaml
prepare_chart "bitnami" "postgresql-ha" $PSQL_VER

# Prepare Redis chart
curl -L $REDIS_VALUES_URL -o $SETUP_DIR/values/redis.values.yaml
prepare_chart "bitnami" "redis" $REDIS_VER

# Prepare Harbor chart
curl -L $HARBOR_VALUES_URL -o $SETUP_DIR/values/harbor.values.yaml
prepare_chart "harbor" "harbor" $HARBOR_VER

# Prepare installation script
cp -v /vagrant/installer.offline.sh $SETUP_DIR/

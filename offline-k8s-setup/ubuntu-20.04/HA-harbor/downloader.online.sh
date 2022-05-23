#!/bin/bash

set -e

ROOT="/home/vagrant"
X86_ARCH="x86_64"
AMD_ARCH="amd64"
OS_NAME="Linux"

source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# Install Docker
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)

# Install Helm
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)

# Install helm/bitnami
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/helm/repo/bitnami.sh)

# Install helm/harbor
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/helm/repo/harbor.sh)

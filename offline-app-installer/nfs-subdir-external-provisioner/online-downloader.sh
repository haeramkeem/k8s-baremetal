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
STUFF="nfs-subdir-external-provisioner"
WORKDIR="/home/vagrant/$STUFF"
NSEP_VER="4.0.16"

# Working directories
mkdir -pv $WORKDIR
mkdir -pv $WORKDIR/debs
mkdir -pv $WORKDIR/bins
mkdir -pv $WORKDIR/etcs
mkdir -pv $WORKDIR/images
mkdir -pv $WORKDIR/charts
mkdir -pv $WORKDIR/chart-values

# Install dependencies
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/basics.sh)
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm.sh)

# Import functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# FILL OUT THE 'AS YOU WANT's
# Download Helm
dl_deb_pkg $WORKDIR/debs/helm <<< "helm"

# Download nfs-common
dl_deb_pkg $WORKDIR/debs/nfs-common <<< "nfs-common libevent-2.1-7"

# Add nfs-subdir-external-provisioner chart repository
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/helm/repo/nfs-subdir-external-provisioner.sh)

# Download chart
cmd="nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version $NSEP_VER"
helm pull $cmd
mv -v nfs-subdir-external-provisioner-$NSEP_VER.tgz \
    $WORKDIR/charts/nfs-subdir-external-provisioner.tgz

# Download values.yaml
curl -L \
    https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/app-install-manifests/helm-repos/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner.yaml \
    -o $WORKDIR/chart-values/nfs-subdir-external-provisioner.values.yaml

# Download required images
helm template $cmd --values $WORKDIR/chart-values/nfs-subdir-external-provisioner.values.yaml \
    | save_img_from_yaml $WORKDIR/images

# FILL OUT THE 'install.sh' CONTENT
touch $WORKDIR/install.sh
chmod 711 $WORKDIR/install.sh
cat <<EOF >> $WORKDIR/install.sh
#!/bin/bash

set -e

WORKDIR=\$(dirname \$0)
NFS_IP=\${2:-"192.168.1.20"}
NFS_PATH=\${3:-"/nfs_shared"}

for img in \$(ls \$WORKDIR/images/*.tar); do
    docker load < \$img
    rm -rf \$img
done

dpkg -i \$WORKDIR/debs/nfs-common/*.deb

if [[ \$1 == "controlplane" ]]; then
    if ! \`helm version &> /dev/null\`; then
        dpkg -i \$WORKDIR/debs/helm/*.deb
    fi

    helm install nsep \$WORKDIR/charts/nfs-subdir-external-provisioner.tgz -f \\
    \$WORKDIR/chart-values/nfs-subdir-external-provisioner.values.yaml \\
    --set nfs.server=\$NFS_IP \\
    --set nfs.path=\$NFS_PATH
fi
EOF

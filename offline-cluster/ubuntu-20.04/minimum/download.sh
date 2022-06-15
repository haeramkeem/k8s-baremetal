#!/bin/bash

# Check superuser
if [[ $(whoami) != "root" ]]
then
    echo "Please run this script in superuser."
    echo "recommend: 'sudo su'"
    exit 1
fi

# Envs
DOCKER_CE="5:20.10.14~3-0~ubuntu-focal"
DOCKER_CLI="5:20.10.14~3-0~ubuntu-focal"
CONTAINERD="1.5.11-1"
KUBE_VER="1.23.5-00"
CNI_YAML="https://projectcalico.docs.tigera.io/manifests/calico.yaml"

# Load functions
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

# Install docker
if ! `docker version &> /dev/null`; then
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/docker.sh)
fi

# Install kubelet, kubectl, kubeadm
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/install/kube.sh) $KUBE_VER

# destination path variables
USR=${1:-"vagrant"}
DST_PATH=/home/$USR/setup
MAN_PATH=$DST_PATH/manifests
DEB_PATH=$DST_PATH/debs
IMG_PATH=$DST_PATH/images

# create dir
mkdir -pv $DST_PATH
mkdir -pv $MAN_PATH
mkdir -pv $DEB_PATH
mkdir -pv $IMG_PATH

# download docker ce
dl_deb_pkg "$DEB_PATH/docker" <<< "docker-ce=$DOCKER_CE docker-ce-cli=$DOCKER_CLI containerd.io=$CONTAINERD" 

# Some environment like `WSL` systemd isn't used to initiate and manage system
#   In this case, use `servive` command instead
#   Ref: https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
#   Check init method: https://unix.stackexchange.com/a/121665
if `pidof systemd &> /dev/null`; then
    systemctl enable --now docker.service
else
    service docker start
    chkconfig docker on
fi

# Download test docker image
docker pull nginx
docker save nginx > $IMG_PATH/nginx.tar

# Download kubelet, kubeadm, kubectl
dl_deb_pkg "$DEB_PATH/k8s" <<< "kubelet=$KUBE_VER kubectl=$KUBE_VER kubeadm=$KUBE_VER"

# download kubernetes images
#   required image list
KUBE_IMG_LIST=$(kubeadm config images list)

#   pull & download images
for KUBE_IMG in $KUBE_IMG_LIST; do
    docker pull $KUBE_IMG
    docker save $KUBE_IMG > $IMG_PATH/$(awk -F/ '{print $NF}' <<< ${KUBE_IMG}).tar
done

# download cni yaml
curl -Lo $MAN_PATH/cni.yaml $CNI_YAML

# download cni-related docker image
cat $MAN_PATH/cni.yaml | save_img_from_yaml $IMG_PATH

# Copy over /vagrant/installer.offline.sh
INS_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-cluster/ubuntu-20.04/minimum/src/install.sh"
curl -Lo $DST_PATH/install.sh $INS_URL

# delete CR
chmod 700 $DST_PATH/install.sh
sed -i 's/\r//g' $DST_PATH/install.sh

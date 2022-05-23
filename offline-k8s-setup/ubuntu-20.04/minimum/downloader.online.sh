#!/usr/bin/env bash

########################
#  CHECK ENV VALIDITY  #
########################

# Check superuser
if [[ $(whoami) != "root" ]]
then
    echo "Please run this script in superuser."
    echo "recommend: 'sudo su'"
    exit 1
fi

###################
#  ENV VARIABLES  #
###################

DOCKER_CE="5:20.10.14~3-0~ubuntu-focal"
DOCKER_CLI="5:20.10.14~3-0~ubuntu-focal"
CONTAINERD="1.5.11-1"
KUBELET="1.23.5-00"
KUBECTL="1.23.5-00"
KUBEADM="1.23.5-00"
API_SERVER="v1.23.5"
CONTROLLER="v1.23.5"
SCHEDULER="v1.23.5"
PROXY="v1.23.5"
PAUSE="3.6"
ETCD="3.5.1-0"
COREDNS="v1.8.6"
CNI_YAML="https://projectcalico.docs.tigera.io/manifests/calico.yaml"

source <(https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

################################
#  INSTALL RELATED REPOSITORY  #
################################

# Install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Install docker apt repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture)\
    signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]\
    https://download.docker.com/linux/ubuntu\
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install kubernetes apt repo
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Update apt
apt-get update

######################
#  DESTINATION PATH  #
######################

# destination path variables
DST_PATH=/home/vagrant
MAN_PATH=$DST_PATH/manifests
DEB_PATH=$DST_PATH/debs
IMG_PATH=$DST_PATH/images

# create dir
# mkdir -pv $DST_PATH
mkdir -pv $MAN_PATH
mkdir -pv $DEB_PATH
mkdir -pv $IMG_PATH

##################################
#  DOWNLOAD & INSTALL DOCKER CE  #
##################################

# download docker ce
dl_deb_pkg "docker-ce=$DOCKER_CE" "$DEB_PATH/docker"
dl_deb_pkg "docker-ce-cli=$DOCKER_CLI" "$DEB_PATH/docker"
dl_deb_pkg "containerd.io=$CONTAINERD" "$DEB_PATH/docker"

# install docker ce
dpkg -i $DEB_PATH/docker/*.deb
# Some environment like `WSL` systemd isn't used to initiate and manage system
#   In this case, use `servive` command instead
#   Ref: https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
#   Check init method: https://unix.stackexchange.com/a/121665
if `pidof systemd`
then
    systemctl enable --now docker.service
else
    service docker start
    chkconfig docker on
fi

# Download test docker image
docker pull nginx
docker save nginx > $IMG_PATH/nginx.tar

#########################
#  DOWNLOAD KUBERNETES  #
#########################

# download kubelet, kubeadm, kubectl
dl_deb_pkg "kubelet=$KUBELET" "$DEB_PATH/k8s"
dl_deb_pkg "kubectl=$KUBECTL" "$DEB_PATH/k8s"
dl_deb_pkg "kubeadm=$KUBEADM" "$DEB_PATH/k8s"

# download kubernetes images
#   required image list
KUBE_IMG_LIST="\
k8s.gcr.io/kube-apiserver:$API_SERVER \
k8s.gcr.io/kube-controller-manager:$CONTROLLER \
k8s.gcr.io/kube-scheduler:$SCHEDULER \
k8s.gcr.io/kube-proxy:$PROXY \
k8s.gcr.io/pause:$PAUSE \
k8s.gcr.io/etcd:$ETCD \
k8s.gcr.io/coredns/coredns:$COREDNS"

#   pull & download images
for KUBE_IMG in $KUBE_IMG_LIST
do
    docker pull $KUBE_IMG
    docker save $KUBE_IMG > $IMG_PATH/${KUBE_IMG//\//.}.tar
done

########################
#  DOWNLOAD CNI ADDON  #
########################

# download cni yaml
curl -Lo $MAN_PATH/cni.yaml $CNI_YAML

# download cni-related docker image
cat $MAN_PATH/cni.yaml | save_img_from_yaml $IMG_PATH

###############################################
#  DOWNLOAD IMAGE REGISTRY (DOCKER REGISTRY)  #
###############################################

# download registry:2
docker pull registry:2
docker save registry:2 > $IMG_PATH/registry.tar

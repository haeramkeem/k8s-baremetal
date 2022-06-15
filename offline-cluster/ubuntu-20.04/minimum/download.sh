#!/bin/bash

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

source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/dl_deb_pkg.sh)
source <(curl -sL https://raw.githubusercontent.com/haeramkeem/sh-it/main/func/save_img_from_yaml.sh)

################################
#  INSTALL RELATED REPOSITORY  #
################################

# Install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Install docker apt repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture)\
    signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]\
    https://download.docker.com/linux/ubuntu\
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install kubernetes apt repo
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt
sudo apt-get update

######################
#  DESTINATION PATH  #
######################

USR=${1:-"vagrant"}
# destination path variables
DST_PATH=/home/$USR/setup
MAN_PATH=$DST_PATH/manifests
DEB_PATH=$DST_PATH/debs
IMG_PATH=$DST_PATH/images

# create dir
mkdir -pv $DST_PATH
mkdir -pv $MAN_PATH
mkdir -pv $DEB_PATH
mkdir -pv $IMG_PATH

##################################
#  DOWNLOAD & INSTALL DOCKER CE  #
##################################

# download docker ce
sudo dl_deb_pkg "$DEB_PATH/docker" <<< "docker-ce=$DOCKER_CE docker-ce-cli=$DOCKER_CLI containerd.io=$CONTAINERD" 

# install docker ce
sudo dpkg -i $DEB_PATH/docker/*.deb
# Some environment like `WSL` systemd isn't used to initiate and manage system
#   In this case, use `servive` command instead
#   Ref: https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
#   Check init method: https://unix.stackexchange.com/a/121665
if `pidof systemd &> /dev/null`; then
    sudo systemctl enable --now docker.service
else
    sudo service docker start
    sudo chkconfig docker on
fi

# Download test docker image
sudo docker pull nginx
sudo docker save nginx > $IMG_PATH/nginx.tar

#########################
#  DOWNLOAD KUBERNETES  #
#########################

# download kubelet, kubeadm, kubectl
sudo dl_deb_pkg "$DEB_PATH/k8s" <<< "kubelet=$KUBELET kubectl=$KUBECTL kubeadm=$KUBEADM"

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
    sudo docker pull $KUBE_IMG
    sudo docker save $KUBE_IMG > $IMG_PATH/$(awk -F/ '{print $NF}' <<< ${KUBE_IMG}).tar
done

########################
#  DOWNLOAD CNI ADDON  #
########################

# download cni yaml
curl -Lo $MAN_PATH/cni.yaml $CNI_YAML

# download cni-related docker image
cat $MAN_PATH/cni.yaml | sudo save_img_from_yaml $IMG_PATH

##############################
#  COPY INSTALLATION SCRIPT  #
##############################

# Copy over /vagrant/installer.offline.sh
INS_URL="https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-cluster/ubuntu-20.04/minimum/installer.offline.sh"
curl -Lo $DST_PATH/install.sh $INS_URL

# delete CR
sudo chmod 700 $DST_PATH/install.sh
sed -i 's/\r//g' $DST_PATH/install.sh

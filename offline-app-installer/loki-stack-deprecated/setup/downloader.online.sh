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

################################
#  INSTALL RELATED REPOSITORY  #
################################

# Install prerequisites
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# Register Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture)\
    signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]\
    https://download.docker.com/linux/ubuntu\
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Register Helm repo
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Update apt
apt-get update

######################
#  DESTINATION PATH  #
######################

# destination path variables
DST_PATH=.
DEB_PATH=$DST_PATH/debs
IMG_PATH=$DST_PATH/images
HLM_PATH=$DST_PATH/helmCharts

# create dir
# mkdir -pv $DST_PATH
mkdir -pv $DEB_PATH
mkdir -pv $IMG_PATH
mkdir -pv $HLM_PATH

##################
#  LOAD MODULES  #
##################
source ./func.dlDebPkgs.sh
source ./func.dlDockerImages.sh

##################
#  DOWNLOAD NFS  #
##################
dlDebPkgs "nfs-kernel-server" "$DEB_PATH/nfs-server"
dlDebPkgs "nfs-common" "$DEB_PATH/nfs-client"

####################
#  INSTALL DOCKER  #
####################
apt-get install docker-ce docker-ce-cli containerd.io -y

##################
#  INSTALL HELM  #
##################
apt-get install helm
if [[ $? != 0 ]]; then
    apt --fix-broken install -y
    apt-get install helm -y
fi
dlDebPkgs "helm" "$DEB_PATH/helm"

##################################
#  DOWNLOAD MANIFESTS FROM HELM  #
##################################

# Add helm repo
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo add grafana https://grafana.github.io/helm-charts

helm repo update

# NFS Provisioner
nfsp="nfs-subdir-external-provisioner" # The name is so fucking long
helm pull $nfsp/$nfsp
mv $nfsp-*.tgz $HLM_PATH/nfs-provisioner.tgz
helm template $HLM_PATH/nfs-provisioner.tgz -f src/nfs-provisioner.values.yaml | dlDockerImages $IMG_PATH

# Loki-stack
helm pull grafana/loki-stack
mv loki-stack-*.tgz $HLM_PATH/loki-stack.tgz
helm template $HLM_PATH/loki-stack.tgz -f src/loki-stack.values.yaml | dlDockerImages $IMG_PATH

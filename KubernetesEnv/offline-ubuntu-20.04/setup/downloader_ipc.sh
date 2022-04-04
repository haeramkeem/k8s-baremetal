#!/usr/bin/env bash

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
DST_PATH=.
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
DOCKER_CE=$(grep "docker-ce:" meta.yaml | awk '{print $2}')
DOCKER_CLI=$(grep "docker-ce-cli:" meta.yaml | awk '{print $2}')
CONTAINERD=$(grep "containerd-io:" meta.yaml | awk '{print $2}')
#   download the packages will all dependencies included from apt
#       `grep -v "i386"` will discard all dependencies with i386 architecture
#       ref: https://stackoverflow.com/a/45489718
DOCKER_PKGS="docker-ce=$DOCKER_CE docker-ce-cli=$DOCKER_CLI containerd.io=$CONTAINERD"
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
    --no-conflicts --no-breaks --no-replaces --no-enhances \
    --no-pre-depends ${DOCKER_PKGS} | grep "^\w" | grep -v "i386")
mkdir -pv $DEB_PATH/docker
mv ./*.deb $DEB_PATH/docker/.

# install docker ce
dpkg -i $DEB_PATH/docker/*.deb
systemctl enable --now docker.service

# Download test docker image
docker pull nginx
docker save nginx > $IMG_PATH/nginx.tar

#########################
#  DOWNLOAD KUBERNETES  #
#########################

# download kubelet, kubeadm, kubectl
KUBELET=$(grep "kubelet:" meta.yaml | awk '{print $2}')
KUBECTL=$(grep "kubectl:" meta.yaml | awk '{print $2}')
KUBEADM=$(grep "kubeadm:" meta.yaml | awk '{print $2}')
K8S_PKGS="kubelet=$KUBELET kubectl=$KUBECTL kubeadm=$KUBEADM"
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests\
    --no-conflicts --no-breaks --no-replaces --no-enhances\
    --no-pre-depends ${K8S_PKGS} | grep "^\w" | grep -v "i386")
mkdir -pv $DEB_PATH/k8s
mv ./*.deb $DEB_PATH/k8s/.

# download kubernetes images
#   version variables
API_SERVER=$(grep "kube-apiserver:" meta.yaml | awk '{print $2}')
CONTROLLER=$(grep "kube-controller-manager:" meta.yaml | awk '{print $2}')
SCHEDULER=$(grep "kube-scheduler:" meta.yaml | awk '{print $2}')
PROXY=$(grep "kube-proxy:" meta.yaml | awk '{print $2}')
PAUSE=$(grep "pause:" meta.yaml | awk '{print $2}')
ETCD=$(grep "etcd:" meta.yaml | awk '{print $2}')
COREDNS=$(grep "coredns:" meta.yaml | awk '{print $2}')

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
CNI_YAML=$(grep "cni-yaml:" meta.yaml | awk '{print $2}')
curl $CNI_YAML -o $MAN_PATH/cni.yaml

# download cni-related docker image
#   as parsing YAML with bash script is limited,
#   pulling docker image based on object-spec YAML has the possibility of malfunction
CNI_IMG_LIST=$(grep "image:" $MAN_PATH/cni.yaml | grep -v "#" | awk '{print $2}' | sort -u)
for CNI_IMG in $CNI_IMG_LIST
do
    docker pull $CNI_IMG
    docker save $CNI_IMG > $IMG_PATH/${CNI_IMG//\//.}.tar
done

###############################################
#  DOWNLOAD IMAGE REGISTRY (DOCKER REGISTRY)  #
###############################################

# download registry:2
docker pull registry:2
docker save registry:2 > $IMG_PATH/registry.tar

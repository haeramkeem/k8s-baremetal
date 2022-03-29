#!/usr/bin/env bash

################################
#  INSTALL RELATED REPOSITORY  #
################################

# Install prerequisites
apt-get update
apt-get install ca-certificates curl gnupg lsb-release

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
# mkdir $DST_PATH
mkdir $MAN_PATH
mkdir $DEB_PATH
mkdir $IMG_PATH

##################################
#  DOWNLOAD & INSTALL DOCKER CE  #
##################################

# Download docker ce
DOCKER_CE=$(grep "docker-ce:" meta.yaml | awk '{print $2}')
DOCKER_CLI=$(grep "docker-ce-cli:" meta.yaml | awk '{print $2}')
CONTAINERD=$(grep "containerd-io:" meta.yaml | awk '{print $2}')
DOCKER_PKGS="docker-ce=$DOCKER_CE docker-ce-cli=$DOCKER_CLI containerd.io=$CONTAINERD"
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
    --no-conflicts --no-breaks --no-replaces --no-enhances \
    --no-pre-depends ${DOCKER_PKGS} | grep "^\w" | grep -v "i386")
mkdir $DEB_PATH/docker
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
mkdir $DEB_PATH/k8s
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

#   pull images
docker pull k8s.gcr.io/kube-apiserver:$API_SERVER
docker pull k8s.gcr.io/kube-controller-manager:$CONTROLLER
docker pull k8s.gcr.io/kube-scheduler:$SCHEDULER
docker pull k8s.gcr.io/kube-proxy:$PROXY
docker pull k8s.gcr.io/pause:$PAUSE
docker pull k8s.gcr.io/etcd:$ETCD
docker pull k8s.gcr.io/coredns/coredns:$COREDNS

#   save images
docker save k8s.gcr.io/kube-apiserver:$API_SERVER > $IMG_PATH/kube-apiserver.tar
docker save k8s.gcr.io/kube-controller-manager:$CONTROLLER > $IMG_PATH/kube-controller-manager.tar
docker save k8s.gcr.io/kube-scheduler:$SCHEDULER > $IMG_PATH/kube-scheduler.tar
docker save k8s.gcr.io/kube-proxy:$PROXY > $IMG_PATH/kube-proxy.tar
docker save k8s.gcr.io/pause:$PAUSE > $IMG_PATH/pause.tar
docker save k8s.gcr.io/etcd:$ETCD > $IMG_PATH/etcd.tar
docker save k8s.gcr.io/coredns/coredns:$COREDNS > $IMG_PATH/coredns.tar

#####################
#  DOWNLOAD CALICO  #
#####################

# download released calico
CALICO=$(grep "calico:" meta.yaml | awk '{print $2}')
curl -LO https://github.com/projectcalico/calico/releases/download/$CALICO/release-$CALICO.tgz
tar -xvzf release-$CALICO.tgz
rm -rf release-$CALICO.tgz

# move all calico images to destination dir
cp ./release-$CALICO/images/* $IMG_PATH/.

# move all calico manifests to destination dir
#   edit YAML to use local image instead of pulling it from registry
sed -i 's/docker.io\///g' ./release-$CALICO/manifests/calico.yaml
cp ./release-$CALICO/manifests/* $MAN_PATH/.
rm -rf ./release-$CALICO

###############################################
#  DOWNLOAD IMAGE REGISTRY (DOCKER REGISTRY)  #
###############################################

# download registry:2
docker pull registry:2
docker save registry:2 > $IMG_PATH/registry.tar

# download sshpass
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests\
    --no-conflicts --no-breaks --no-replaces --no-enhances\
    --no-pre-depends sshpass | grep "^\w" | grep -v "i386")
mkdir $DEB_PATH/sshpass
mv ./*.deb $DEB_PATH/sshpass/.

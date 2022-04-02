#!/usr/bin/env bash

################################
#  INSTALL RELATED REPOSITORY  #
################################

# install EPEL repo
yum install epel-release -y

# install docker repo
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

# install kubernetes repo
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# Recreate cache
yum makecache fast

######################
#  DESTINATION PATH  #
######################

# destination path variables
DST_PATH=.
MAN_PATH=$DST_PATH/manifests
RPM_PATH=$DST_PATH/rpms
IMG_PATH=$DST_PATH/images

# create dir
# mkdir -pv $DST_PATH
mkdir -pv $MAN_PATH
mkdir -pv $RPM_PATH
mkdir -pv $IMG_PATH

##################################
#  DOWNLOAD & INSTALL DOCKER CE  #
##################################

# download docker ce
DOCKER_CE=$(grep "docker-ce:" meta.yaml | awk '{print $2}')
DOCKER_CLI=$(grep "docker-ce-cli:" meta.yaml | awk '{print $2}')
CONTAINERD=$(grep "containerd-io:" meta.yaml | awk '{print $2}')
yumdownloader --resolve docker-ce-$DOCKER_CE docker-ce-cli-$DOCKER_CLI containerd.io-$CONTAINERD
mkdir -pv $RPM_PATH/docker
cp -irv ./*.rpm $RPM_PATH/docker/.

# install docker ce
rpm -ivh --replacefiles --replacepkgs *.rpm
systemctl enable --now docker.service
rm -rf *.rpm

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
yumdownloader --resolve kubelet-$KUBELET kubeadm-$KUBEADM kubectl-$KUBECTL
mkdir -pv $RPM_PATH/k8s
mv ./*.rpm $RPM_PATH/k8s/.

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

########################
#  DOWNLOAD CNI ADDON  #
########################

# download cni yaml
CNI_YAML=$(grep "cni-yaml:" meta.yaml | awk '{print $2}')
curl $CNI_YAML -o $MAN_PATH/cni.yaml

# download cni-related docker image
#   as parsing YAML with bash script is limited,
#   pulling docker image based on object-spec YAML has the possibility of malfunction
for CNI_IMG in $(grep "image:" $MAN_PATH/cni.yaml | awk '{print $2}' | sort -u)
do
    docker pull $CNI_IMG
    docker save $CNI_IMG > $IMG_PATH/$(echo ${CNI_IMG//\//-} | cut -d ':' -f 1).tar
done

###############################################
#  DOWNLOAD IMAGE REGISTRY (DOCKER REGISTRY)  #
###############################################

# download registry:2
docker pull registry:2
docker save registry:2 > $IMG_PATH/registry.tar

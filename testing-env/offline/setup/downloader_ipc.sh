#!/usr/bin/env bash

################################
#  INSTALL RELATED REPOSITORY  #
################################

# install EPEL repo
yum install epel-release -y

# install docker repo
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-nightly

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
# mkdir $DST_PATH
mkdir $MAN_PATH
mkdir $RPM_PATH
mkdir $IMG_PATH

##################################
#  DOWNLOAD & INSTALL DOCKER CE  #
##################################

# download docker ce
yumdownloader --resolve docker-ce
mkdir $RPM_PATH/docker
cp ./*.rpm $RPM_PATH/docker/.

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
yumdownloader --resolve kubelet kubeadm kubectl
mkdir $RPM_PATH/k8s
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

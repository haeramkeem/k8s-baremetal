#!/usr/bin/env bash

# Check superuser
if [[ $(whoami) != "root" ]]
then
    echo "Please run this script in superuser."
    echo "recommend: 'sudo su'"
    exit 1
fi

###########################
#  LOAD META.YAML CONFIG  #
###########################

# Bash YAML parser
#   ref: https://stackoverflow.com/a/21189044
function parse_yaml {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Parse `meta.yaml`
eval $(parse_yaml meta.yaml "META_")

# Use short name
DOCKER_CE=$META_docker_versions_ce
DOCKER_CLI=$META_docker_versions_cli
CONTAINERD=$META_docker_versions_containerd
KUBELET=$META_kubernetes_versions_kubelet
KUBECTL=$META_kubernetes_versions_kubectl
KUBEADM=$META_kubernetes_versions_kubeadm
API_SERVER=$META_kubernetes_versions_kube_apiserver
CONTROLLER=$META_kubernetes_versions_kube_controller_manager
SCHEDULER=$META_kubernetes_versions_kube_scheduler
PROXY=$META_kubernetes_versions_kube_proxy
PAUSE=$META_kubernetes_versions_pause
ETCD=$META_kubernetes_versions_etcd
COREDNS=$META_kubernetes_versions_coredns
CNI_YAML=$META_cni_yaml

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
yumdownloader --resolve docker-ce-$DOCKER_CE docker-ce-cli-$DOCKER_CLI containerd.io-$CONTAINERD
mkdir -pv $RPM_PATH/docker
mv ./*.rpm $RPM_PATH/docker/.

# install docker ce
rpm -ivh --replacefiles --replacepkgs $RPM_PATH/docker/*.rpm
systemctl enable --now docker.service

# Download test docker image
docker pull nginx
docker save nginx > $IMG_PATH/nginx.tar

#########################
#  DOWNLOAD KUBERNETES  #
#########################

# download kubelet, kubeadm, kubectl
yumdownloader --resolve kubelet-$KUBELET kubeadm-$KUBEADM kubectl-$KUBECTL
mkdir -pv $RPM_PATH/k8s
mv ./*.rpm $RPM_PATH/k8s/.

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
#   as parsing YAML with bash script is limited,
#   pulling docker image based on object-spec YAML has the possibility of malfunction
CNI_IMG_LIST=$(sed -nr "s/[^#]\s*image:\s*['\"]?([^'\"]+)['\"]?/\1/gp" $MAN_PATH/cni.yaml | sort -u)
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

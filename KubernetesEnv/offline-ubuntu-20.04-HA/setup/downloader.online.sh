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

#####################
#  LOCAL FUNCTIONS  #
#####################

# Bash YAML parser
#   ref: https://stackoverflow.com/a/21189044
#   usage:
#       $1: filepath
#       $2: variable prefix
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

# download .deb from apt
#   download the packages with all dependencies included from apt
#       `grep -v "i386"` will discard all dependencies with i386 architecture
#       ref: https://stackoverflow.com/a/45489718
#   usage:
#       $1: package name (only one permitted)
#       $2: package save directory path (mkdir if path not found)
function dl_deb {
    apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
        --no-conflicts --no-breaks --no-replaces --no-enhances \
        --no-pre-depends ${1} | grep "^\w" | grep -v "i386")
    mkdir -pv $2
    mv ./*.deb $2/.
}

###########################
#  LOAD META.YAML CONFIG  #
###########################

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
HAPROXY_SHORT=$META_haproxy_version_short
HAPROXY_LONG=$META_haproxy_version_long
KA_VER=$META_keepalived_version

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
eval $(dl_deb "docker-ce=$DOCKER_CE" "$DEB_PATH/docker")
eval $(dl_deb "docker-ce-cli=$DOCKER_CLI" "$DEB_PATH/docker")
eval $(dl_deb "containerd.io=$CONTAINERD" "$DEB_PATH/docker")

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
eval $(dl_deb "kubelet=$KUBELET" "$DEB_PATH/k8s")
eval $(dl_deb "kubectl=$KUBECTL" "$DEB_PATH/k8s")
eval $(dl_deb "kubeadm=$KUBEADM" "$DEB_PATH/k8s")

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

##################################
#  DOWNLOAD HAPROXY / KEEPALIVED #
##################################

# Register HAProxy registry
apt-get install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-$HAPROXY_SHORT -y
apt-get update

# Download package
eval $(dl_deb "haproxy=$HAPROXY_LONG" "$DEB_PATH/haproxy")
eval $(dl_deb "keepalived=$KA_VER" "$DEB_PATH/keepalived")

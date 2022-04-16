#!/usr/bin/env bash

########################
#  CHECK ENVIRONMENTS  #
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

#####################
#  LOCAL VARIABLES  #
#####################

# Parse `meta.yaml`
eval $(parse_yaml meta.yaml "META_")

# Use short name
MASTER_COUNT=$META_node_master_count
WORKER_COUNT=$META_node_worker_count
MASTER_IP_BASE=$META_node_master_ip_base
WORKER_IP_BASE=$META_node_worker_ip_base
MASTER_HNAME_BASE=$META_node_master_hname_base
WORKER_HNAME_BASE=$META_node_worker_hname_base

##################
#  SYSTEM SETUP  #
##################

# Kubernetes requires the disabling of the partition swapping
#   swapoff -a to disable swapping
swapoff -a
#   sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+\s+swap\s+.+)/#\1/g' /etc/fstab

# Use iptables and br_netfilter kernel module for IPv4 & IPv6 routing table
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter
modprobe overlay
sysctl --system

# Set local DNS - this will make communication between nodes with hostname instead of IP
for (( i=1; i<=$MASTER_COUNT; i++ )); do
    echo "$MASTER_IP_BASE$i $MASTER_HNAME_BASE$1" >> /etc/hosts; done
for (( i=1; i<=$WORKER_COUNT; i++ )); do
    echo "$WORKER_IP_BASE$i $WORKER_HNAME_BASE$1" >> /etc/hosts; done

#######################
#  INSTALL DOCKER CE  #
#######################

# Install Docker
dpkg -i ./debs/docker/*.deb
rm -rf ./debs/docker # Remove installation files 
systemctl enable --now docker

# Configure cgroup driver
mkdir -pv /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

#   installing docker with .deb automatically starts the docker
#       thus, reloading docker after write a daemon.json file is required
#       the command `systemctl enable --now docker.service` would not load this configuration
systemctl daemon-reload
systemctl restart docker

###################################
#  INSTALL KUBERNETES COMPONENTS  #
###################################

# Load all images
FILES="./images/*.tar"
for f in $FILES
do
    docker load < $f
    rm -rf $f # Remove image files
done

# Install Kubernetes
dpkg -i ./debs/k8s/*.deb
rm -rf ./debs/k8s # Remove installation files
systemctl enable --now kubelet

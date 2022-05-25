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

# HAProxy installer
#   Synopsis
#       $1: Frontend port
#       $2: Backend server count
#       $3: Backend server ip base
#       $4: Backend server hostname base
#       $5: Backend server port
function ins_haproxy {
    dpkg -i ./debs/haproxy/*.deb
    cat ./src/haproxy.cfg.template | sed "s/{APISERVER_DEST_PORT}/$1/g" > haproxy.cfg
    for (( i=1; i<=$2; i++ )); do
        echo "    server $4$i $3$i:$5 check" >> haproxy.cfg
    done
    mv ./haproxy.cfg /etc/haproxy/haproxy.cfg
    systemctl restart haproxy
}

#####################
#  LOCAL VARIABLES  #
#####################

# Parse `meta.yaml`
eval $(parse_yaml meta.yaml "META_")

# Use short name
POD_CIDR=$META_kubernetes_const_cidr
NODE_NIC=$META_node_nic
LB_FE_PORT=$META_haproxy_fe_port
LB_BE_COUNT=$META_node_master_count
LB_BE_IP_BASE=$META_node_master_ip_base
LB_BE_HNAME_BASE=$META_node_master_hname_base
LB_BE_PORT=$META_kubernetes_const_apiserver_port
APISERVER_VIP=$META_keepalived_vip

# Auto-generated
CERT_KEY=$(kubeadm certs certificate-key)
BASE_COMMAND="kubeadm init --certificate-key $CERT_KEY --pod-network-cidr $POD_CIDR"
CURR_IP=$(ip -4 addr show ${NODE_NIC} | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

#############################
#  INSTALL HA REQUIREMENTS  #
#############################

# Synopsis
#   $1:
#       NONE: Single master setup
#       `-L` or `--load-balance`: Multi-master setup
#       `-A` or `--active-standby`: Multi-master setup with backup server
case "$1" in

    ########################
    #  SINGLE MASTER NODE  #
    ########################

    "")
        echo "MODE: Single master setup"

        # Init kubernetes cluster
        $BASE_COMMAND --apiserver-advertise-address $CURR_IP
        ;;

    ##########################
    #  SINGLE LOAD BALANCER  #
    ##########################

    "-L"|"--load-balance")
        echo "MODE: Multi-master setup with single load balancer"

        # Install HAProxy
        ins_haproxy ${LB_FE_PORT} ${LB_BE_COUNT} ${LB_BE_IP_BASE} ${LB_BE_HNAME_BASE} ${LB_BE_PORT}

        # Init kubernetes cluster
        $BASE_COMMAND --apiserver-advertise-address $CURR_IP --upload-certs --control-plane-endpoint $CURR_IP:$LB_FE_PORT
        ;;

    ########################
    #  DUAL LOAD BALANCER  #
    ########################

    "-A"|"--active-standby")
        echo "MODE: Multi-master setup with dual active-standby load balancer"

        # Install HAProxy
        ins_haproxy ${LB_FE_PORT} ${LB_BE_COUNT} ${LB_BE_IP_BASE} ${LB_BE_HNAME_BASE} ${LB_BE_PORT}

        # Install Keepalived
        dpkg -i ./debs/keepalived/*.deb
        cat ./src/keepalived.real.conf | sed "s/{NODE_NIC}/$NODE_NIC/g" > keepalived.conf
        sed -i "s/{APISERVER_VIP}/$APISERVER_VIP/g" keepalived.conf
        mv keepalived.conf /etc/keepalived/keepalived.conf
        systemctl restart keepalived

        # Init kubernetes cluster
        $BASE_COMMAND --apiserver-advertise-address $APISERVER_VIP --upload-certs --control-plane-endpoint $APISERVER_VIP:$LB_FE_PORT
        ;;

    ###########################
    #  ABORT KUBERNETES INIT  #
    ###########################

    *)
        echo "Unknown command '$1'"
        echo "* Synopsis: 'init_cluster.offline.sh [OPTION]'"
        echo "* OPTION:"
        echo "  - default: Single master setup"
        echo "  - '-L' or '--load-balance': Multi-master setup with single load balancer"
        echo "  - '-A' or '--active-standby': Multi-master setup with dual active-standby load balancer"
        exit 1
        ;;

esac

###############################
#  POST-INSTALLATION PROCESS  #
###############################

# Setup Kubernetes config path
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI Plugin
kubectl apply -f ./manifests/cni.yaml

##########################
#  GENERATE JOIN SCRIPT  #
##########################

# Create destination directory
mkdir -pv dest

# Generate join script for worker
JOIN_STR=$(kubeadm token create --print-join-command)
#   Replace join command
cat src/join.sh.template | \
    sed "s/{JOIN_STR}/$JOIN_STR/g" > \
    dest/join_as_worker.offline.sh

# Generate join script for master
if [[ $1 != "" ]]; then

    # Replace join command
    cat src/join.sh.template | \
        sed "s/{JOIN_STR}/$JOIN_STR--control-plane --certificate-key $CERT_KEY/g" > \
        dest/join_as_master.offline.sh

    # Uncomment kube config setup command
    sed -i "s/#%KUBE_CFG%//g" dest/join_as_master.offline.sh

fi

# Generate join script for sorry master
if [[ $1 == "-A" || $1 == "--active-standby" ]]; then

    # Replace join command
    cat src/join.sh.template | \
        sed "s/{JOIN_STR}/$JOIN_STR--control-plane --certificate-key $CERT_KEY/g" > \
        dest/join_as_sorry.offline.sh

    # Uncomment LB and keepalived installation command
    sed -i "s/#%DUAL_LB%//g" dest/join_as_sorry.offline.sh

    # Uncomment kube config setup command
    sed -i "s/#%KUBE_CFG%//g" dest/join_as_sorry.offline.sh

    # Prepare HAProxy installation
    #   Move HAProxy packages
    mv ./debs/haproxy ./dest/haproxy
    #   Move HAProxy config file
    cat ./src/haproxy.cfg.template | \
        sed "s/{APISERVER_DEST_PORT}/$LB_FE_PORT/g" > dest/haproxy.cfg
    for (( i=1; i<=$LB_BE_COUNT; i++ )); do
        echo "    server $LB_BE_HNAME_BASE\$i $LB_BE_IP_BASE\$i:$LB_BE_PORT check" >> \
        dest/haproxy.cfg
    done

    # Prepare keepalived installation
    #   Move keepalived packages
    mv ./debs/keepalived ./dest/keepalived
    #   Move keepalived config file
    cat ./src/keepalived.sorry.conf | \
        sed "s/{NODE_NIC}/$NODE_NIC/g" > dest/keepalived.conf
    sed -i "s/{APISERVER_VIP}/$APISERVER_VIP/g" dest/keepalived.conf

fi

chmod 711 dest/*.sh

#######################
#  ENDING INITIATION  #
#######################

echo ""
echo ""
echo "* The Kubernetes cluster is initiated"
echo "  - Script for joining to the cluster is prepared to './dest/' dir"
echo "  - You can copy this directory to other node to execute join command"
echo "  - SCP example: 'scp -p dest USERNAME@IP:PATH'"
echo "  - 'dest/join_as_worker.offline.sh' let the node join to the cluster as worker node"

if [[ $1 != "" ]]; then
    echo "  - 'dest/join_as_master.offline.sh' let the node join to the cluster as master node"
fi

if [[ $1 == "-A" || $1 == "--active-standby" ]]; then
    echo "  - 'dest/haproxy' and 'dest/keepalived' directory is used to install HAProxy and keepalived to your node"
    echo "  - 'dest/join_as_sorry.offline.sh' let the node join to the cluster as backup sorry master node"
fi

#!/bin/bash

SETUP_DIR=$(dirname $0)

for img in $(ls $SETUP_DIR/*.tar); do
    docker load < $img
    rm -rf $img
done

function install_chart {
    local release=$1
    local chart=$2
    local namespace=$3

    helm install $release \
        $SETUP_DIR/charts/$chart.tgz \
        --namespace $namespace \
        --values $SETUP_DIR/values/$chart.values.yaml
}

if [[ $1 == "controlplane" ]]; then
    if ! `helm version &> /dev/null`; then
        dpkg -i $SETUP_DIR/debs/helm/*.deb
    fi

    NAMESPACE="harbor"
    kubectl create namespace $NAMESPACE

    install_chart "pg" "postgresql" $NAMESPACE
    install_chart "redis" "redis" $NAMESPACE
    install_chart "harbor" "harbor" $NAMESPACE
fi

#!/bin/bash

WORKDIR=$(dirname $0)

# COMMON scripts
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# CONTROLPLANE scripts
if [[ $1 == "controlplane" ]]; then
    NAMESPACE=${2:-"loki-stack"}
    RELEASE=${3:-"loki"}

    helm install $RELEASE $WORKDIR/charts/loki-stack.tgz \
        --create-namespace \
        -n $NAMESPACE \
        -f $WORKDIR/values/loki-stack.values.yaml
fi

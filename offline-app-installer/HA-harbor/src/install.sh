#!/bin/bash

WORKDIR=$(dirname $0)

# COMMON scripts
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# CONTROLPLANE scripts
if [[ $1 == "controlplane" ]]; then
    RELEASE=${2:-"harbor"}
    NAMESPACE=${3:-"default"}

    helm install $RELEASE $WORKDIR/charts/harbor.tgz \
        -n $NAMESPACE \
        -f $WORKDIR/values/harbor.values.yaml
fi

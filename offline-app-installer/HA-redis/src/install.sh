#!/bin/bash

WORKDIR=$(dirname $0)

# COMMON scripts
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# CONTROLPLANE scripts
# Synopsis: ./install.sh controlplane ${NAMESPACE} ${RELEASE}
if [[ $1 == "controlplane" ]]; then
    NAMESPACE=${2:-"default"}
    RELEASE=${3:-"redis"}

    helm install $RELEASE $WORKDIR/charts/redis.tgz \
        -n $NAMESPACE \
        -f $WORKDIR/values/redis.values.yaml
fi

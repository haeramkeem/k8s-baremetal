#!/bin/bash

WORKDIR=$(dirname $0)

# COMMON scripts
for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

# CONTROLPLANE scripts
# Synopsis: ./install.sh controlplane ${NAMESPACE} ${RELEASE_NAME}
if [[ $1 == "controlplane" ]]; then
    NAMESPACE=${2:-"default"}
    RELEASE=${3:-"pg"}

    helm install $RELEASE $WORKDIR/charts/postgresql-ha.tgz \
        -n $NAMESPACE \
        -f $WORKDIR/values/postgresql-ha.values.yaml
fi

#!/bin/bash

WORKDIR=$(dirname $0)

for img in $(ls $WORKDIR/images/*.tar); do
    docker load < $img
    rm -rf $img
done

if [[ $1 == "controlplane" ]]; then
    RELEASE=${2:-"pg"}
    NAMESPACE=${3:-"default"}

    helm install $RELEASE $WORKDIR/charts/postgresql-ha.tgz \
        -n $NAMESPACE \
        -f $WORKDIR/values/postgresql-ha.values.yaml
fi

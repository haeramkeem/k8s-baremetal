#!/bin/bash

WORKDIR=$(dirname $0)

# Install Helm
if ! `helm version &> /dev/null`; then
    $WORKDIR/helm/install.sh
fi

# Load images
for img in $(ls $WORKDIR/images/*.tar); do
    sudo ctr -n k8s.io images import $img
    rm -rf $img
done

# Install Elasticsearch with Helm
if [[ $1 == "controlplane" ]]; then
    NAMESPACE=${2:+"--create-namespace -n $2"}

    helm install $WORKDIR/charts/elasticsearch.tgz \
        $NAMESPACE \
        -f $WORKDIR/values/elasticsearch.yaml
fi

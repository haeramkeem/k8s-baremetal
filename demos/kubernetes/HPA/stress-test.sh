#!/bin/bash
PODIP=$(kubectl get pods -o=jsonpath='{.items[0].status.podIP}')

for(( ; ; ))
do
    curl -sL $PODIP
done

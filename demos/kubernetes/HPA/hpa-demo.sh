#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

BASEURL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/demos/kubernetes/HPA"

# Create Metrics server object
kubectl create -f $BASEURL/metrics-server.yaml

#   Creation result
kubectl get deployment -n kube-system metrics-server
echo ""

# Create testing deployment
kubectl create -f $BASEURL/hpa-hname-pods.yaml

#   Start autoscaling
kubectl autoscale deployment hpa-hname-pods --min=1 --max=30 --cpu-percent=50

#   Creation result
kubectl get deployment hpa-hname-pods
echo ""

# Wait 1 minute before testing
echo "Wait 1 minute before testing..."
sleep 1m

# Start stressing
bash <(curl -sL $BASEURL/stress-test.sh) >> log &

# Watch autoscaling
watch kubectl top pods

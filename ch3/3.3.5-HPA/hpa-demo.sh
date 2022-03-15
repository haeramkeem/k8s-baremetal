#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create Metrics server object
METRICS_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/metrics-server.yaml
kubectl create -f $METRICS_URL

#   Creation result
kubectl get deployment -n kube-system metrics-server

# Create testing deployment
DPY_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/hpa-hname-pods.yaml
kubectl create -f $DPY_URL

#   Creation result
kubectl get deployment hpa-hname-pods

# Start autoscaling
kubectl autoscale deployment hpa-hname-pods --min=1 --max=30 --cpu-percent=50

# Start stressing
STRESS_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/stress-test.sh
bash <(curl -sL $STRESS_URL) >> log &

# Watch autoscaling
watch kubectl top pods

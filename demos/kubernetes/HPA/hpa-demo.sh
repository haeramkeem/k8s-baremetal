#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create Metrics server object
echo "----- CREATE METRICS SERVER -----"
METRICS_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/metrics-server.yaml
kubectl create -f $METRICS_URL

#   Creation result
kubectl get deployment -n kube-system metrics-server
echo ""

# Create testing deployment
echo "----- CREATE TESTING DEPLOYMENT -----"
DPY_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/hpa-hname-pods.yaml
kubectl create -f $DPY_URL

#   Start autoscaling
kubectl autoscale deployment hpa-hname-pods --min=1 --max=30 --cpu-percent=50

#   Creation result
kubectl get deployment hpa-hname-pods
echo ""

# Wait 1 minute before testing
echo "Wait 1 minute before testing..."
sleep 1m

# Start stressing
STRESS_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/stress-test.sh
bash <(curl -sL $STRESS_URL) >> log &

# Watch autoscaling
watch kubectl top pods

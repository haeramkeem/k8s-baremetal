#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

BASEURL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/demos/kubernetes/ConfigMap"

# Create MetalLB object to demo with ConfigMap of MetalLB
bash <(curl -sL $BASEURL/metallb-install.sh)

# Create testing deployment
kubectl create deployment cfgmap --image=sysnet4admin/echo-hname
kubectl expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80

# Waiting for testing deployment to run
echo "Waiting for testing deployment to run..."
sleep 1m
OLD_IP=$(kubectl get services cfgmap-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo ""

# Apply new ConfigMap spec
kubectl apply -f $BASEURL/metallb-l2config-new.yaml

# Restart MetalLB pods, and services
kubectl delete pods --all -n metallb-system
kubectl delete service cfgmap-svc
kubectl expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80

# Waiting for applying ConfigMap setup
echo "Waiting for applying ConfigMap setup..."
sleep 20s
NEW_IP=$(kubectl get services cfgmap-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo ""

# Show testing result
echo "----- TEST RESULT -----"
echo "IP changed from $OLD_IP to $NEW_IP due to modification of the ConfigMap"
echo ""

# Cleanup
kubectl delete deployment cfgmap
kubectl delete service cfgmap-svc

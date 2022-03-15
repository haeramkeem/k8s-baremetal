#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create MetalLB object to demo with ConfigMap of MetalLB
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb-install.sh)

# Create testing deployment
kubectl create deployment cfgmap --image=sysnet4admin/echo-hname
kubectl expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80

# Waiting for testing deployment to run
echo "Waiting for testing deployment to run..."
sleep 30s
OLD_IP=$(kubectl get services cfgmap-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Apply new ConfigMap spec
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.4.2/metallb-l2config-new.yaml

# Restart MetalLB pods, and services
kubectl delete pods --all -n metallb-system
kubectl delete service cfgmap-svc
kubectl expose deployment cfgmap --type=LoadBalancer --name=cfgmap-svc --port=80

echo "Waiting for ConfigMap setup..."
sleep 30s
NEW_IP=$(kubectl get services cfgmap-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "----- TEST RESULT -----"
echo "IP changed from $OLD_IP to $NEW_IP due to modification of the ConfigMap"

kubectl delete deployment cfgmap
kubectl delete service cfgmap-svc

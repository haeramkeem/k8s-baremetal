#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create MetalLB pods (contoller and speakers)
#   1 controller and 2 speakers will be created
echo "----- METALLB PODS -----"
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb.yaml

# Show creation result
kubectl get pods -n metallb-system -o wide
echo ""

# Create ConfigMap for MetalLB
echo "----- METALLB CONFIGMAP -----"
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb-l2config.yaml

# Show creation result
kubectl get configmap -n metallb-system
echo ""
echo "INSTALLATION DONE"

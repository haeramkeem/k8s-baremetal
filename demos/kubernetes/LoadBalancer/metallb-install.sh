#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

BASEURL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/demos/kubernetes/LoadBalancer"

# Create MetalLB pods (contoller and speakers)
#   1 controller and 2 speakers will be created
kubectl apply -f $BASEURL/metallb.yaml

# Show creation result
kubectl get pods -n metallb-system -o wide
echo ""

# Create ConfigMap for MetalLB
kubectl apply -f $BASEURL/metallb-l2config.yaml

# Show creation result
kubectl get configmap -n metallb-system
echo ""

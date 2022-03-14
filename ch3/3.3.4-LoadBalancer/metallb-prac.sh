#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create deployment for testing
kubectl create deployment lb-hname-pods --image=sysnet4admin/echo-hname
kubectl create deployment lb-ip-pods --image=sysnet4admin/echo-ip

# By scaling the pods, u can see that the request are distributed to each pod
kubectl scale deployment lb-hname-pods --replicas=2

# Show creation result
echo "\n----- DEPLOYMENT FOR TESTING -----"
kubectl get pods

# Create MetalLB pods (contoller and speakers)
#   1 controller and 2 speakers will be created
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb.yaml

# Show creation result
echo "\n----- METALLB PODS -----"
kubectl get pods -n metallb-system -o wide

# Create ConfigMap for MetalLB
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb-l2config.yaml

# Show creation result
echo "\n----- METALLB CONFIGMAP -----"
kubectl get configmap -n metallb-system

# Expose each deployment to LoadBalancer
kubectl expose deployment lb-hname-pods --type=LoadBalancer --name=lb-hname-svc --port=80
kubectl expose deployment lb-ip-pods --type=LoadBalancer --name=lb-ip-svc --port=80

# Wait 1 minute before testing to finish setup
echo "Wait 1 minute before testing..."
sleep 1m

# Test Load Balancer
HNAME_EIP=$(kubectl get service lb-hname-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
IP_EIP=$(kubectl get service lb-ip-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "\n----- BALANCING DEPLOYMENT TEST -----"
echo "Request to 'lb-hname-svc': $(curl $HNAME_EIP)"
echo "Request to 'lb-ip-svc': $(curl $IP_EIP)"

echo "\n----- BALANCING POD TEST -----"
for (( i=0; i<=10; i++ ))
do
    curl $HNAME_EIP
done

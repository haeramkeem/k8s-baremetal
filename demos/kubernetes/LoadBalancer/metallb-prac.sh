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
kubectl get pods
echo ""

# Expose each deployment to LoadBalancer
kubectl expose deployment lb-hname-pods --type=LoadBalancer --name=lb-hname-svc --port=80
kubectl expose deployment lb-ip-pods --type=LoadBalancer --name=lb-ip-svc --port=80

# Show exposure result
kubectl get services
echo ""

# Wait 1 minute before testing to finish setup
echo "Wait 1 minute before testing..."
sleep 1m
echo ""

# Test Load Balancer
HNAME_EIP=$(kubectl get service lb-hname-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
IP_EIP=$(kubectl get service lb-ip-svc -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "----- BALANCING DEPLOYMENT TEST -----"
echo "Request to 'lb-hname-svc': $(curl -s $HNAME_EIP)"
echo "Request to 'lb-ip-svc': $(curl -s $IP_EIP)"
echo ""

echo "----- BALANCING POD TEST -----"
for (( i=0; i<=10; i++ ))
do
    curl -s $HNAME_EIP
done
echo ""

# Cleanup
kubectl delete deployment lb-hname-pods
kubectl delete deployment lb-ip-pods
kubectl delete service lb-hname-svc
kubectl delete service lb-ip-svc
kubectl delete -f $METALLB_URL

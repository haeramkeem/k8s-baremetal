#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

BASEURL="https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/demos/kubernetes/Ingress"

# Create 2 deployment for testing
kubectl create deployment in-hname-pod --image=sysnet4admin/echo-hname
kubectl create deployment in-ip-pod --image=sysnet4admin/echo-ip

# Create Ingress controller pod and additional objects
kubectl apply -f $BASEURL/ingress-nginx.yaml

# Show creation result
kubectl get pods -n ingress-nginx
echo ""

# Create Ingress object
kubectl apply -f $BASEURL/ingress-config.yaml

# Show creation result
kubectl get ingress
echo ""

# Expose Ingress with NodePort
kubectl apply -f $BASEURL/ingress.yaml

# Show Exposure result
kubectl get services -n ingress-nginx
echo ""

# Expose Deployment with Cluster-IP
kubectl expose deployment in-hname-pod --name=hname-svc-default --port=80,443
kubectl expose deployment in-ip-pod --name=ip-svc --port=80,443

# Show Exposure result
echo "----- DEPLOYMENT SERVICE -----"
kubectl get services
echo ""

# Wait 1 minute before testing to finish setup
echo "Wait 1 minute before testing..."
sleep 1m

# Test Ingress
NODEIP=$(kubectl get node node01 -o=jsonpath='{.status.addresses[0].address}')
HTTP_PORT=30100
HTTPS_PORT=30101

echo "----- HTTP INGRESS TEST -----"
echo "Request for Default URL Path"
curl http://$NODEIP:$HTTP_PORT
echo "Request for /ip"
curl http://$NODEIP:$HTTP_PORT/ip
echo ""

echo "----- HTTPS INGRESS TEST -----"
echo "Request for Default URL Path"
curl -k https://$NODEIP:$HTTPS_PORT
echo "Request for /ip"
curl -k https://$NODEIP:$HTTPS_PORT/ip
echo ""

# Cleanup
kubectl delete deployment in-hname-pod
kubectl delete deployment in-ip-pod
kubectl delete service hname-svc-default
kubectl delete service ip-svc
kubectl delete -f $CONT_URL
kubectl delete -f $ING_URL

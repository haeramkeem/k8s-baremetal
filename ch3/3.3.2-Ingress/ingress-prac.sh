#!/bin/bash

#################################################################################
# This practice is based on sysnet4admin/_Book_k8sInfra                         #
# Testing environment: https://www.katacoda.com/courses/kubernetes/playground   #
#################################################################################

# Create 2 deployment for testing
kubectl create deployment in-hname-pod --image=sysnet4admin/echo-hname
kubectl create deployment in-ip-pod --image=sysnet4admin/echo-ip

# Install Ingress controller pod
CONT_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.2-Ingress/ingress-nginx.yaml
kubectl apply -f $CONT_URL

# Show installation result
echo "----- INGRESS CONTROLLER POD -----"
kubectl get pods -n ingress-nginx
echo ""

# Install Ingress configuration
ING_URL=https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.2-Ingress/ingress-config.yaml
kubectl apply -f $ING_URL

# Show configuration result
echo "----- INGRESS CONFIGURATION RESULT -----"
kubectl get ingress
echo ""

# Expose Ingress
kubectl apply -f https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.2-Ingress/ingress.yaml

# Show Ingress NodePort
echo "----- INGRESS SERVICE -----"
kubectl get services -n ingress-nginx
echo ""

# Expose Deployment
kubectl expose deployment in-hname-pod --name=hname-svc-default --port=80,443
kubectl expose deployment in-ip-pod --name=ip-svc --port=80,443

# Show Deployment NodePort
echo "----- DEPLOYMENT SERVICE -----"
kubectl get services
echo ""

# Wait 1 minute before testing
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

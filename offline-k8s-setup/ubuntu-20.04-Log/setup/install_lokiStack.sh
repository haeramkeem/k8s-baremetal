#!/bin/bash

# Install helm
dpkg -i ./debs/helm/*.deb

# Install NFS external provisioner
helm install nfs-provisioner ./helmCharts/nfs-subdir-external-provisioner

# Install PLG stack
lokiNamespace="loki-stack"
lokiRelease="loki"
kubectl create namespace $lokiNamespace
helm install $lokiRelease ./helmCharts/loki-stack --namespace $lokiNamespace

adminPassword=$(kubectl get secret --namespace ${lokiNamespace} ${lokiRelease}-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)

echo ""
echo ""
echo "Loki stack is deployed successfully"
echo "* Type 'kubectl port-forward --address 0.0.0.0 --namespace $lokiNamespace service/$lokiRelease-grafana 3000:80' to access with your browser"
echo "* And login with ID: admin & PW: $adminPassword"
echo ""
echo ""

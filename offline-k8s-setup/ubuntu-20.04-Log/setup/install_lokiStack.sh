#!/bin/bash

# Install helm
dpkg -i ./debs/helm/*.deb

# Install NFS external provisioner
helm install nfs-provisioner helmCharts/nfs-provisioner.tgz -f src/nfs-provisioner.values.yaml

# Install PLG stack
loki_n="loki-stack"
loki_r="loki"
kubectl create namespace $loki_n
helm install $loki_r helmCharts/loki-stack.tgz -f src/loki-stack.values.yaml --namespace $loki_n

adminPassword=$(kubectl get secret --namespace ${loki_n} ${loki_r}-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)

echo ""
echo ""
echo "Loki stack is deployed successfully"
echo "* Type 'kubectl port-forward --address 0.0.0.0 --namespace $loki_n service/$loki_r-grafana 3000:80' to access with your browser"
echo "* And login with ID: admin & PW: $adminPassword"
echo ""
echo ""

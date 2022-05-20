#!/bin/bash

ROOT=$(dirname $0)

# Install HAProxy
dpkg -i $ROOT/deb/haproxy/*.deb
systemctl stop haproxy
systemctl disable haproxy

# Allow the haproxy binary to bind to ports 80 and 443:
setcap cap_net_bind_service=+ep /usr/sbin/haproxy

# Install the HAProxy Kubernetes Ingress Controller
cp $ROOT/bin/haproxy-ingress-controller /usr/local/bin/

cp $ROOT/service/haproxy-ingress.service /lib/systemd/system/
systemctl enable haproxy-ingress
systemctl start haproxy-ingress

# Copy kube config to this server
CP_UNAME="blue"
CP_IP="192.168.1.101"
mkdir -p /root/.kube
scp ${CP_UNAME}@${CP_IP}:/etc/kubernetes/admin.conf /root/.kube/config
chown -R root:root /root/.kube

# Install Bird
dpkg -i $ROOT/deb/bird/*.deb

# Copy over bird.conf
cp $ROOT/service/bird.conf /etc/bird/bird.conf
sudo systemctl enable bird
sudo systemctl restart bird

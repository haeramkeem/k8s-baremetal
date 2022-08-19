#!/bin/bash

ROOT=$(dirname $0)

# Install HAProxy
dpkg -i $ROOT/deb/haproxy/*.deb
systemctl stop haproxy
systemctl disable haproxy

# Allow the haproxy binary to bind to ports 80 and 443:
setcap cap_net_bind_service=+ep /usr/sbin/haproxy

# Install HAProxy Kubernetes Ingress Controller
cp -v $ROOT/bin/haproxy-ingress-controller /usr/local/bin/

# Install HAProxy service
cp -v $ROOT/etc/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
cp -v $ROOT/etc/haproxy-ingress.service /lib/systemd/system/
systemctl enable haproxy-ingress
systemctl start haproxy-ingress

# Copy kube config to this cluster
CP_UNAME="blue"
CP_IP="192.168.1.101"
mkdir -p /root/.kube
scp ${CP_UNAME}@${CP_IP}:/home/blue/.kube/config /root/.kube/config
chown -R root:root /root/.kube
systemctl restart haproxy-ingress

# Install Bird
dpkg -i $ROOT/deb/bird/*.deb

# Copy over bird.conf
cp $ROOT/etc/bird.conf /etc/bird/bird.conf
sudo systemctl enable bird
sudo systemctl restart bird

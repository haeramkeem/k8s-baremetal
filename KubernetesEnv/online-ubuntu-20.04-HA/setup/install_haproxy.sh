#!/bin/bash

# Install HAProxy
apt-get install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.5 -y
apt-get update
apt-get install haproxy -y

# Overwrite HAProxy settings
cp ./haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy

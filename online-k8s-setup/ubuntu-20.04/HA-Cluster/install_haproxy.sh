#!/bin/bash

#####################
#  INSTALL HAPROXY  #
#####################

# Install latest stable version of HAProxy
apt-get install --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.5 -y
apt-get update
apt-get install haproxy -y

# Overwrite HAProxy settings
rm -rf /etc/haproxy/haproxy.cfg
curl https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/online-k8s-setup/ubuntu-20.04-HA/install_haproxy.sh -o /etc/haproxy/haproxy.cfg
systemctl restart haproxy

#!/bin/bash

# Install prerequisites
apt-get update
apt-get install -y git vim net-tools

# vim configuration 
echo 'alias vi=vim' >> /etc/profile
rm -rf ~/.vimrc
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc

# Set local DNS - this will make communication between nodes with hostname instead of IP
#   vagrant cannot parse and delivery shell code.
#       Master nodes ($1)
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i k8s-m$i" >> /etc/hosts; done
#       Worker nodes ($2)
for (( i=1; i<=$2; i++  )); do echo "192.168.1.20$i k8s-w$i" >> /etc/hosts; done

# Config DNS server for external communication
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF


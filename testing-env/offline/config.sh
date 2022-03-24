#!/usr/bin/env bash

# vim configuration 
echo 'alias vi=vim' >> /etc/profile
rm -rf ~/.vimrc
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc

# docker repo
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-nightly

# kubernetes repo
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# Recreate cache
yum makecache fast

# Prepare downloading dependancies
mkdir ~/dest
mkdir ~/dest/manifests
mkdir ~/dest/yums
mkdir ~/dest/images

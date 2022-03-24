#!/usr/bin/env bash

# vim configuration 
echo 'alias vi=vim' >> /etc/profile
rm -rf ~/.vimrc
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc

# git configuration
git config --global user.name haeramkeem
git config --global user.name ewqdsacxz2345@gmail.com
git clone https://github.com/haeramkeem/k8s-exercise.git
mv k8s-exercise ~/.

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
yum makecache fast

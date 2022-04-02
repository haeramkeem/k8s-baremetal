#!/bin/bash

yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker repo
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-nightly

yum install docker-ce -y
systemctl enable --now docker.service

yum install java-1.8.0-openjdk-devel -y

git clone https://github.com/sysnet4admin/_Book_k8sInfra.git


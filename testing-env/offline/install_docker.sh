#!/usr/bin/env bash

# Download and install docker ce
echo "----- INSTALLING DOCKER CE -----"
yumdownloader --resolve docker-ce
tar cvzf ~/dest/yum/docker.tar.gz *.rpm
rpm -ivh --replacefiles --replacepkgs *.rpm
systemctl enable --now docker.service
rm -rf *.rpm
echo "Docker CE RPM saved to '~/dest/yums/docker.tar.gz'"
echo ""

# Download test docker image
echo "----- NGINX TEST IMAGE DOWNLOAD -----"
docker pull nginx
docker save nginx > ~/images/nginx.tar
echo "Nginx image saved to '~/dest/images/nginx.tar'"

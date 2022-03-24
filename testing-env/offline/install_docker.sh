#!/usr/bin/env bash

# Download and install docker ce
echo "----- INSTALLING DOCKER CE -----"
yumdownloader --resolve docker-ce
mkdir ~/dest/rpms/docker
cp ./*.rpm ~/dest/rpms/docker/.
rpm -ivh --replacefiles --replacepkgs *.rpm
systemctl enable --now docker.service
rm -rf *.rpm
echo "Docker CE RPM saved to '~/dest/yums/docker/*'"
echo ""

# Download test docker image
echo "----- NGINX TEST IMAGE DOWNLOAD -----"
docker pull nginx
docker save nginx > ~/dest/images/nginx.tar
echo "Nginx image saved to '~/dest/images/nginx.tar'"

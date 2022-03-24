#!/usr/bin/env bash

echo "----- DOWNLOADING K8S -----"
yumdownloader --resolve kubelet kubeadm kubectl
tar cvzf ~/dest/yums/k8s.tar.gz *.rpm
rm -rf *.rpm
echo "Kubernetes package (kubelet, kubeadm, kubectl) saved to '~/dest/yums/k8s.tar.gz'"

echo "----- DOWNLOADING DEPENDENT IMAGES -----"
docker pull k8s.gcr.io/kube-apiserver:v1.18.0
docker pull k8s.gcr.io/kube-controller-manager:v1.18.0
docker pull k8s.gcr.io/kube-scheduler:v1.18.0
docker pull k8s.gcr.io/kube-proxy:v1.18.0
docker pull k8s.gcr.io/pause:3.2
docker pull k8s.gcr.io/etcd:3.4.3-0
docker pull k8s.gcr.io/coredns:1.6.7

docker save k8s.gcr.io/kube-apiserver:v1.18.0 > ~/dest/images/kube-apiserver.docker.tar
docker save k8s.gcr.io/kube-controller-manager:v1.18.0 > ~/dest/images/kube-controller-manager.docker.tar
docker save save k8s.gcr.io/kube-scheduler:v1.18.0 > ~/dest/images/kube-scheduler.docker.tar
docker save k8s.gcr.io/kube-proxy:v1.18.0 > ~/dest/images/kube-proxy.docker.tar
docker save k8s.gcr.io/pause:3.2 > ~/dest/images/pause.docker.tar
docker save k8s.gcr.io/etcd:3.4.3-0 > ~/dest/images/etcd.docker.tar
docker save k8s.gcr.io/coredns:1.6.7 > ~/dest/images/coredns.docker.tar
echo "k8s-dependant docker image saved to '~/dest/images/*'"

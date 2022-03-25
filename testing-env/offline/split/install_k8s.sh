#!/usr/bin/env bash

echo "----- DOWNLOADING K8S -----"
yumdownloader --resolve kubelet kubeadm kubectl
mkdir ~/dest/rpms/k8s
mv ./*.rpm ~/dest/rpms/k8s/.
echo "Kubernetes package (kubelet, kubeadm, kubectl) are saved to '~/dest/yums/k8s.tar.gz'"

echo "----- DOWNLOADING K8S IMAGES -----"
API_SERVER=$(grep "kube-apiserver:" meta.yaml | awk '{print $2}')
CONTROLLER=$(grep "kube-controller-manager:" meta.yaml | awk '{print $2}')
SCHEDULER=$(grep "kube-cheduler:" meta.yaml | awk '{print $2}')
PROXY=$(grep "kube-proxy:" meta.yaml | awk '{print $2}')
PAUSE=$(grep "pause:" meta.yaml | awk '{print $2}')
ETCD=$(grep "etcd:" meta.yaml | awk '{print $2}')
COREDNS=$(grep "coredns/coredns:" meta.yaml | awk '{print $2}')

docker pull k8s.gcr.io/kube-apiserver:$API_SERVER
docker pull k8s.gcr.io/kube-controller-manager:$CONTROLLER
docker pull k8s.gcr.io/kube-scheduler:$SCHEDULER
docker pull k8s.gcr.io/kube-proxy:$PROXY
docker pull k8s.gcr.io/pause:$PAUSE
docker pull k8s.gcr.io/etcd:$ETCD
docker pull k8s.gcr.io/coredns:$COREDNS

docker save k8s.gcr.io/kube-apiserver:$API_SERVER > ~/dest/images/kube-apiserver.docker.tar
docker save k8s.gcr.io/kube-controller-manager:$CONTROLLER > ~/dest/images/kube-controller-manager.docker.tar
docker save save k8s.gcr.io/kube-scheduler:$SCHEDULER > ~/dest/images/kube-scheduler.docker.tar
docker save k8s.gcr.io/kube-proxy:$PROXY > ~/dest/images/kube-proxy.docker.tar
docker save k8s.gcr.io/pause:$PAUSE > ~/dest/images/pause.docker.tar
docker save k8s.gcr.io/etcd:$ETCD > ~/dest/images/etcd.docker.tar
docker save k8s.gcr.io/coredns:$COREDNS > ~/dest/images/coredns.docker.tar
echo "k8s related docker image are saved to '~/dest/images/*'"

echo "----- DOWNLOADING CALICO -----"
CALICO=$(grep "calico:" meta.yaml | awk '{print $2}')

wget https://github.com/projectcalico/calico/releases/download/$CALICO/release-$CALICO.tgz
tar -xvzf release-$CALICO.tgz
cd ./release-$CALICO
cp ./images/* ~/dest/images/.
echo "calico related docker image are saved to '~/dest/images/*'"

sed -i 's/docker.io\///g' ./manifests/calico.yaml
cp ./manifests/* ~/dest/manifests/.
cd ..
rm -rf ./release-$CALICO.tgz ./release-$CALICO
echo "calico manifests are saved to '~/dest/manifests/*'"

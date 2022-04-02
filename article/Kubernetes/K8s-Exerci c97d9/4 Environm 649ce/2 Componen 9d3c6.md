# 2. Components and Calico

```bash
kubectl get pods --all-namespaces -o=custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
IP:.status.podIP,\
NODE:.spec.nodeName
```

```bash
NAMESPACE     NAME                                      IP              NODE
kube-system   calico-kube-controllers-99c9b6f64-b64c9   172.16.171.68   m-k8s   # Calico Controller Deployment
kube-system   calico-node-2pm4f                         192.168.1.103   w3-k8s  # Calico DaemonSet for w3-k8s
kube-system   calico-node-lm97w                         192.168.1.10    m-k8s   # Calico DaemonSet for m-k8s
kube-system   calico-node-qd7cr                         192.168.1.101   w1-k8s  # Calico DaemonSet for w1-k8s
kube-system   calico-node-sf4f4                         192.168.1.102   w2-k8s  # Calico DaemonSet for w2-k8s
kube-system   coredns-66bff467f8-dhp6k                  172.16.171.69   m-k8s   # CoreDNS Deployment
kube-system   coredns-66bff467f8-g4ft2                  172.16.171.70   m-k8s   # CoreDNS Deployment
kube-system   etcd-m-k8s                                192.168.1.10    m-k8s   # etcd Pod
kube-system   kube-apiserver-m-k8s                      192.168.1.10    m-k8s   # API server Pod
kube-system   kube-controller-manager-m-k8s             192.168.1.10    m-k8s   # Controller Manager Pod
kube-system   kube-proxy-hjm6x                          192.168.1.10    m-k8s   # Kube-proxy DaemonSet for m-k8s
kube-system   kube-proxy-jbtrj                          192.168.1.102   w2-k8s  # Kube-proxy DaemonSet for w2-k8s
kube-system   kube-proxy-qjcqs                          192.168.1.103   w3-k8s  # Kube-proxy DaemonSet for w3-k8s
kube-system   kube-proxy-tdgt7                          192.168.1.101   w1-k8s  # Kube-proxy DaemonSet for w1-k8s
kube-system   kube-scheduler-m-k8s                      192.168.1.10    m-k8s   # Scheduler Pod
```

## Offline installation

[Install Docker CE on an Offline CentOS 7 Machine](https://www.centlinux.com/2019/02/install-docker-ce-on-offline-centos-7-machine.html)

[Install Kubernetes (K8s) Offline on CentOS 7](https://www.centlinux.com/2019/04/install-kubernetes-k8s-offline-on-centos-7.html#:~:text=Installing)

```bash
[root@docker-offline ~]# systemctl enable kubelet.service
Created symlink from /etc/systemd/system/multi-user.target.wants/kubelet.service to /usr/lib/systemd/system/kubelet.service.
[root@docker-offline ~]# systemctl start kubelet.service
```
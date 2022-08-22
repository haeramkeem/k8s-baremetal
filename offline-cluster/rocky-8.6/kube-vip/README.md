# OFFLINE/RHEL8 High-available Kubernetes cluter bootstrapper: Kube-vip solution

## Download all requirements

- To download using `VirtualBox` and `Vagrant`:

```bash
vagrant up
```

- To download requirements to the existing node:

```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-iac/main/offline-cluster/rocky-8.6/kube-vip/download.sh)
```

## Initiate cluster on offline node

- To initiate a K8s cluster:

```bash
./install -m init
```

- To join cluster as a controlplane node:

```bash
# Use ${CERT_KEY} provided when u initiate real master node
./install -m controlplane -c ${CERT_KEY}
```

- To join cluster as an worker node:

```bash
./install -m worker
```

## About valid options...

### download.sh

- `$1` : Download path. Default value is `$PWD`.

### install.sh

- `-m` : Initiation `mode`. The valid values are as follows:
    - `init` : Initiating a cluster.
    - `controlplane` : Bootstrap a controlplane node.
    - `worker` : Bootstrap an worker node.
    - default : Does not initiate the cluster; just installing the requirements.

- `-c` : Certificate key for controlplane. It's required only when the provided value for `-m` flag is `controlplane`.

- `-k` : Mode of the Kube-vip installation. Default is `arp`.

- `-s` : Skip installing the basic K8s components (like kubelet, kubeadm, etc)

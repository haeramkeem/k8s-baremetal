# OFFLINE/RHEL8 Kubernetes cluter bootstrapper

## Download all requirements

- To download using `VirtualBox` and `Vagrant`:

```bash
vagrant up
```

- To download requirements to the existing node:

```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-cluster/rocky-8.6/minimum/download.sh)
```

## Initiate cluster on offline node

- To initiate real(active) master node:

```bash
./install -m controlplane
```

- To join cluster as an worker node:

```bash
./install -m worker
```

## Options

### download.sh

- `$1` : Download path. Default value is `$PWD`.

- `$2` : Kubernetes version. Default value is `lastest stable`

### install.sh

- `-m` : Initiation `mode`. The valid values are as follows:
    - `controlplane` : Bootstrap a master node.
    - `worker` : Bootstrap a worker node.
    - default : Does not initiate the node; just installing the requirements.

- `-M` : The number of master node in cluster.

- `-W` : The number of worker node in cluster.

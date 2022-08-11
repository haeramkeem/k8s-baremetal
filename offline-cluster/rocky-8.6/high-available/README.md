# OFFLINE/RHEL8 High-available Kubernetes cluter bootstrapper

## Download all requirements

- To download using `VirtualBox` and `Vagrant`:

```bash
vagrant up
```

- To download requirements to the existing node:

```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/clustermaker/main/offline-cluster/rocky-8.6/high-available/download.sh)
```

## Initiate cluster on offline node

- To initiate a real(active) master node:

```bash
./install -m real
```

- To join cluster as a sorry(standby) master node:

```bash
# Use ${CERT_KEY} provided when u initiate real master node
./install -m sorry -c ${CERT_KEY}
```

- To join cluster as a normal master node:

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
    - `real` : Bootstrap real(active) master node.
    - `sorry` : Bootstracp sorry(standby) master node.
    - `controlplane` : Bootstrap normal master node.
    - `worker` : Bootstrap worker node.
    - default : Does not initiate the cluster; just installing the requirements.

- `-c` : Certificate key for controlplane. It's required only when the provided value for `-m` flag is `sorry` or `controlplane`.

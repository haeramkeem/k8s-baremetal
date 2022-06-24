# PLG (Loki Stack) logging architecture

## Prerequisite

* The values for the helm chart is customized regarding the number of workers as 2.
* Initiated & joined Kubernetes cluster is needed.

## Online node setup

* Type `vagrant up` will make ubuntu 20.04 online node VM with all scripts copied.
* Connect to a online node via `vagrant ssh` and execute the command below:

```bash
cd ~/setup
./downloader.online.sh
```

* After downloading all the packages, copy `setup` directory to offline nodes.

## Offline node setup

### Install and setup NFS

* To use dynamic provisioning, the NFS has to be installed to certain node.
* Use `install_nfs.offline.sh` to install NFS to each node.
* On NFS server node:

```bash
./install_nfs.offline.sh server
```

* On NFS client node:

```bash
./install_nfs.offline.sh client
```

### Load required docker images

* Load required docker images by using `load_docker_images.offline.sh` script.
* Execute the command below in all the nodes in the cluster.

```bash
./load_docker_images.offline.sh
```

### Install HELM, External NFS Provisioner, and PLG Stack (Loki stack)

* The `install_lokiStack.sh` script will install HELM, External NFS Provisioner, and PLG Stack to the cluster.

```bash
./install_lokiStack.sh
```

* After all the installation is done, the guide for the next step will printed to the console like:

```
Loki stack is deployed successfully
* Type 'kubectl port-forward --address 0.0.0.0 --namespace loki-stack service/loki-grafana 3000:80' to access with your browser
* And login with ID: admin & PW: ${ADMIN_PASSWORD}
```

* Follow the printed guide to access Grafana dashboard from your host PC.
* The `install_lokiStack.sh` script creates loki stack pods & services etc to the `loki-stack` namespace. So you can get the status of the components using `loki-stack` namespace.

```bash
kubectl get all -n loki-stack
```

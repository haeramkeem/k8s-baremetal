# Highly Available Kubernetes Cluster

## Prerequisite
* "Vagrant" must be installed on your host computer.
* As a VM provider, "VirtualBox" must be installed on your host computer.
* 4 VMs are used in this exercise; 3 master nodes and 1 worker node. Thus, all the VMs must be prepared beforehand.
## Online node setup
* Type `vagrant up` will make ubuntu 20.04 online node VM with all scripts copied.
* Connect to a online node via `vagrant ssh` and execute the command below:
```bash
cd ~/setup
./downloader.online.sh
```
* After downloading all the packages, copy `setup` directory to offline nodes.
## Offline node setup
* Docker CE, Kubelet, Kubectl, and Kubeadm must be installed in all of the offline nodes.
* Executing the command below will install the Docker and Kubernetes components.
```bash
./install_docker_k8s.offline.sh
```
## Initiate cluster
* Executing `init_cluster.offline.sh` will initiate cluster.
* When the option is not provided, this script will consider as a single master setup.
* If you want to initiate the cluster with the multiple master setup and no backup load balancer, use `-L` or `--load-balance` option:
```bash
# or `./init_cluster.offline.sh --load-balance`
./init_cluster.offline.sh -L
```
* If you want to initiate the cluster with the multiple master setup and additional load balancer as a backup, use `-A` or `--active-standby` option:
```bash
# or you can: `./init_cluster.offline.sh --active-standby`
./init_cluster.offline.sh -A
```
* Executing the script will generate `dest` directory. It contains dependant packages and scripts for joining the cluster.
* Copy `dest` directory to all other nodes to join the cluster.
## Join cluster
* If you want to join current node to the cluster as a worker node, use `join_as_a_worker.offline.sh` script.
```bash
./join_as_a_worker.offline.sh
```
* If you want to join current node to the cluster as a master node (with no additional load balancer installed), use `join_as_a_master.offline.sh` script.
```bash
./join_as_a_master.offline.sh
```
* If you want to join current node to the cluster as a master node with additional backup load balancer installed, use `join_as_a_sorry.offline.sh` script.
```bash
./join_as_a_sorry.offline.sh
```

# Highly Available Kubernetes Cluster

## Prerequisite
* All the nodes require Docker, Kubelet, Kubeadm and Kubectl.
* Installation script is prepared in `install_all.sh`.
* Or, u can execute the script with the command below:
```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/KubernetesEnv/online-ubuntu-20.04-HA/install_all.sh)
```
## Triple control plane nodes with single HAProxy load balancer
* A frontend node requires HAProxy with its configuration.
* Installation script is prepared in `install_haproxy.sh`.
* Configuration for HAProxy is prepared in `haproxy.cfg`.
* This configuration opens the `26443` port for endpoint port and balances the traffic to 6443 port of backend nodes by RR.
* U can executes the `install_haproxy.sh` script without downloading it:
```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/KubernetesEnv/online-ubuntu-20.04-HA/install_haproxy.sh)
```
## Triple control plane nodes with double HAProxy load balancer and keepalived
* The keepalived real server and sorry server both requires the HAProxy load balancer.
* Use `install_haproxy.sh` to install HAProxy.
* Installation script for `keepalived` is prepared in `install_keepalived.sh`.
* This script requires additional flag: `--real` for the real server and `--sorry` for the sorry server.
* The keepalived process generates a VIP (Virtual IP), which is `192.168.1.10` (u can modify it in the `keepalived.*.config` files.
* The command below initiates the keepalived process for real server:
```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/KubernetesEnv/online-ubuntu-20.04-HA/install_keepalived.sh) --real
```
* The command below initiates the keepalived process for sorry server:
```bash
bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/infra-exercise/main/KubernetesEnv/online-ubuntu-20.04-HA/install_keepalived.sh) --sorry
```

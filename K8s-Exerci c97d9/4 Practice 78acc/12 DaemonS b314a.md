# 12. DaemonSet

## About DaemonSet

- The **DaemonSet** is the workload resource that makes pods for each node
- So, the number of the pods inside of a **DaemonSet** is always the same as the number of the node
    - When u add a new node to the cluster, then all the pods which are bound with the **DaemonSet** will be created automatically
- The reason for using **DaemonSet** is simple: When u need some node-managing pods, it’s better to organize them as a **DaemonSet**
- The common use cases for **DaemonSet** are:
    1. Communication tools between inside and outside of the node → like *Calico*, *Kube-proxy*, and *MetalLB speaker*
    2. Logger for each node
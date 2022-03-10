# 4. Practice

## Tools

1. **Docker**: Container distribution platform
2. **Kubernetes**: Container orchestration system
3. **Jenkins**: CI (Continous Integration) and CD (Continous Deployment)
4. **Prometheus & Grafana**: Monitoring & Dashboard
5. **Kubeadm**: Kubernetes installation tool → Configure all Kubernetes cluster
6. **Calico**: Container Network Interface (CNI) → Configure the communication of the Kubernetes cluster

## Kubectl Commands

1. `kubectl get nodes`
    - Show all information for node
2. `kubectl get pods [ARG]`
    - Show all information for pods
    - `-n $NAMESPACE`: Specify the namespace for the pods → Default is the *default namespace*
    - `-o $OPTIONS`: Specify the options
        - `wide`: Show additional information for each pod
    - Examples
        
        ```bash
        kubectl get pods # Show pods for the default namespace
        kubectl get pods -n kube-system # Show pods for the Kubernetes system pods
        kubectl get pods -o wide # Show pods with additional information
        ```
        
3. `kubectl create $OBJECT $OBJ_NAME [ARG]`
    - Create Kubernetes object
    - `-f $FILEPATH`: Specify the path of the *object spec file (YAML, JSON)*
        - With this option, u don’t have to specify the `$OBJECT`
    - `--image=$IMAGE`: Specify the image of the object’s container instead of *object spec file*
        - However, u can’t create a pod with this option; U have to use *object spec file* if u wanna make only a pod
        - If u wanna make only one pod with a specified image, use `run` method described below
        - U **MUST** specify the workload object instead of only one pod if u wanna use this option
    - Examples
        
        ```bash
        kubectl create deployment dpy-nginx --image=nginx # Create deployment with nginx image
        kubectl create -f nginx-pod.yaml # Create nginx pod with object spec file
        ```
        
4. `kubectl run $POD_NAME [ARG]`
    - This is how to make a pod with no *object spec file*
    - `--image=$IMAGE`: Specify the image of the pod
    - Examples
        
        ```bash
        kubectl run nginx-pod --image=nginx # Create nginx pod with a specified image
        ```
        
5.
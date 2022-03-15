# 11. Horizontal Pod Autoscaler (HPA)

## About HPA

- Kubernetes supports autoscaling of the deployment; It’s called **Horizontal Pod Autoscaler (HPA)**
- Here’s how HPA works:
    1. Specify the resource limitations for the container of each pod → These limitations are kinda *criteria* for the autoscaling
    2. Start autoscaling with specifying the minimum, maximum number of pods, and autoscale condition which is a percentage of resource limitations
    3. While running, the *Metrics Server* collects the usage of the resources of each node with the help of *Kubelet* and send it to **HPA** through *Kube-apiserver*
    4. When the autoscale condition is fulfilled, in other words, the percentage of the resource usage is above a certain value, **HPA** requests the scaling of the pod to the deployment to increase the number of the pod
    5. On contrary, when the resource usage is lower, HPA request the decrement of the number of the pod
- This is how **HPA** calculates the number of pods needed:
    - Let’s say CPU limitation is *10m*
        - *m* means *milliunits*, thus 1000m equals 1 CPU
        - So, *10m* is same with 0.01 CPU
    - And let’s say u set the autoscale condition as 50%
    - In these settings, HPA will scale the deployment when the resource usage of a pod is above *5m*
    - So, when resource usage for a pod is *24m*, HPA calculates the number of pods needed by *24m/5m*, which is 5
        - See the formula for calculating the total number
        
        $NumberOfReplica = CurrentUsage/(ResourceLimit*Percentage/100)$
        
    - Eventually, the deployment makes 4 more replicas to fit in that number

## Metrics Server

- **Metrics Server** watches the usage of resources for each pod with the help of the *Kubelet*
- And send it to the **HPA** through the *Kube-apiserver* → It’s called *Kubernetes built-in autoscaling pipelines*
- Metrics server object URL → Create **Metrics Server** object with `kubectl create -f`
    
    ```bash
    https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5-HPA/metrics-server.yaml
    ```
    
    - In this object spec file, additional flags are added when comparing with the original release code
    - `--kubelet-insecure-tls`: Allow unsafe communication for TLS
    - `--kubelet-prefered-address-types=InternalIP`: Let kubelet use InternalIP firstly
    
    ```bash
    kubectl get pods -o=custom-columns=\
    NAME:.metadata.name,\
    REQ:.spec.containers[0].resources.requests.cpu,\
    LIMITS:.spec.containers[0].resources.limits.cpu
    ```
    

## Demo

- See .sh file to figure out the demo:
    
    [k8s-exercise/hpa-demo.sh at main · haeramkeem/k8s-exercise](https://github.com/haeramkeem/k8s-exercise/blob/main/ch3/3.3.5-HPA/hpa-demo.sh)
    
- Live demo:
    
    ```bash
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.5HPA/hpa-demo.sh)
    ```
    
    - The number of pods is start with 1, but it increases as HPA scale the deployment
    - [NOTE]: When `error: metrics not available yet` error occurs, wait a few more minutes
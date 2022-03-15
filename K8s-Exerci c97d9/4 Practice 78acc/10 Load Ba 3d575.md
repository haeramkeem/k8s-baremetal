# 10. Load Balancer

# About Load Balancer

- While *Ingress* provides a balancing feature, there is a kinda inefficient process
- That is, while using *Ingress*, a request is reached to the pod which is inside of the node after the request is reached to the *node* and then forwarded to the *Ingress Controller*
- However, **Load Balancer** receives the request and forward it to the corresponded deployment directly
- But **Load Balancer** also has a problem: **Load Balancer** must be installed *outside* of the cluster, so unless u use the cloud service provider, it’s a little bit tricky to use that
- If ur using a cloud provider like AWS, Google cloud platform, or Microsoft Azure, just use the command below:
    
    ```bash
    kubectl expose deployment $DEPLOYMENT_NAME --type=LoadBalancer --name=$SERVICE_NAME
    ```
    

# Demo with “MetalLB”

- **MetalLB** is a project targeting bare-metal Kubernetes cluster
- So, if ur using an on-premises cluster system, u can use it instead of the cloud provided Load Balancer
- **MetalLB** provides Load Balancer that uses L2 protocol (Data link layer protocols, such as ARP and NDP) and L3 protocol (Network layer protocols, such as BGP → but Wikipedia says BGP is a L7 protocol → wtf)
- When u specify the protocol and external IP on the MetalLB, the **MetalLB speaker** makes the routes for the pods, and the leader of the speaker which is selected by the L2 network controls overall routes → I think the **MetalLB controller** is the leader, but I’m not sure
- But as the MetalLB project noted, MetalLB is a beta system → treat this demo just for understanding the Kubernetes Load Balancer

### Demo

- See the .sh file to figure out the demo
    
    [k8s-exercise/metallb-prac.sh at main · haeramkeem/k8s-exercise](https://github.com/haeramkeem/k8s-exercise/blob/main/ch3/3.3.4-LoadBalancer/metallb-prac.sh)
    
- Live testing:
    
    ```bash
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.4-LoadBalancer/metallb-prac.sh)
    ```
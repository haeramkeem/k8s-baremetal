# 9. Ingress

# About Ingress

- An **Ingress** is one type of service, that routes each request to corresponded deployment by the *URL path*
- The reason for using **Ingress** is that when u use *NodePort* *only*, u have to open one port per deployment
- So, u can think that each request is routed by the port when u use *NodePort only*
- But, when  u use **Ingress** with NodePort instead of *NodePort only*, opening only one port is enough
- In short, **Ingress** opens one port with the help of NodePort and routes each request to the corresponded deployment using the *URL path*
- So, here’s the flow for setup and operation of **Ingress**
    1. Ingress controller opens one port using NodePort
    2. When a request is received through the port, that request is forwarded to the Ingress controller
    3. Ingress controller forwards the request using *URL path* to *Cluster-IP service*
        - *Cluster-IP service* provides routing with deployment’s name and the *iptable*
        - When u creates a service with default type (no service type specified), then Kubernetes creates the *Cluster-IP service*
    4. *Cluster-IP service* forwards the request to the pod
- To use **Ingress**, u have to:
    1. Create **Ingress Controller** pod
    2. Create **Ingress** object → This is kinda *configuration of the Ingress controller* to specify the router and corresponded action
    3. Expose the **Ingress** using NodePort (Create NodePort service)
    4. Expose each deployment using Cluster-IP (Create Cluster-IP service)

# Kubectl Ingress command

- In short, **Ingress** opens a port with the help of NodePort and routes each request to the corresponded deployment by the *URL path*
1. Create **Ingress controller pod**
    - `kubectl apply -f $INGRESS_SPECFILE`: Create **Ingress controller pod** via *object spec*
    - `kubectl apply -f $INGRESS_CONFIGFILE`: Configurate Ingress
2. Show Ingress information
    - `kubectl get pods -n $INGRESS_NAMESPACE`: As **Ingress controller** is one of the pods, u can see it via `get pods` command
        - Usually, **Ingress controller** has another namespace other than *default namespace*. So, u have to specify the namespace of Ingress controller via `-n` option
    - `kubectl get ingress`: Show ingress status
        - `-o $OUTFORM`: Similarly with other `get` command usage, u can specify the format of the output using this option. → `wide`, `yaml`, `json`

# Demo with “NGINX Ingress Controller”

- A lot of Ingress Controllers are developed; In this demo, we’re using “NGINX Ingress Controller”
    - Here’s official documentation
        
        [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
        
- See .sh file to figure out the demo:
    
    [k8s-exercise/ingress-prac.sh at main · haeramkeem/k8s-exercise](https://github.com/haeramkeem/k8s-exercise/blob/main/ch3/3.3.2-Ingress/ingress-prac.sh)
    
- Live testing:
    
    ```bash
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.3.2-Ingress/ingress-prac.sh)
    ```
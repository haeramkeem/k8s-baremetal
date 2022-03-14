# 8. NodePort, Services

# NodePort

![Source: [https://www.docker.com/blog/designing-your-first-application-kubernetes-communication-services-part3/kubernetes-nodeport-service/](https://www.docker.com/blog/designing-your-first-application-kubernetes-communication-services-part3/kubernetes-nodeport-service/)](8%20NodePort%20f5021/Untitled.png)

Source: [https://www.docker.com/blog/designing-your-first-application-kubernetes-communication-services-part3/kubernetes-nodeport-service/](https://www.docker.com/blog/designing-your-first-application-kubernetes-communication-services-part3/kubernetes-nodeport-service/)

- As one type of Service, **NodePort** opens the certain port of all nodes to make them accessible for the external host
- That is, when the external host accesses a node with opened port, *KubeProxy* for that node forward it to the NodePort service object and then forward to the target pod
- This is an example scenario:
    - The port opened by **NodePort** is `30000`
    - An IP address for `node01` is `192.168.2.10` and that for `node02` is `192.168.2.11`
    - NGINX pod is running on each node → and the opened port `30000` is linked to NGINX’s port (80)
    - When the user accesses `192.168.2.10:30000`, all the requests are forwarded to **NodePort** by *KubeProxy***,** and **NodePort** forwards them to the `node01` or `node02` with `80` port

# Practice

## Kubectl command for services

1. `kubectl get services`
    - Show all information for services
    - Examples
        
        ```bash
        kubectl get services # Show services
        ```
        

## Create NodePort object

1. By *object spec*
    - Object spec file example
        
        ```yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: np-svc # Can change
        spec:
          selector:
            app: np-pods # Name of the deployment u want to link
          ports:
            - name: http
              protocol: TCP
              port: 80 # Private port - Depends on protocol
              targetPort: 80 # Maybe same with `port`
              nodePort: 30000 # This is published port
          type: NodePort
        ```
        
    - Create object: `kubectl create -f $SERVICE_OBJ_FILEPATH`
2. By `expose` command
    - `kubectl expose $OBJECT $OBJECT_NAME [$ARGS]`
        - `--type=$SERVICE_TYPE`: Type of the service, to make **NodePort** object, specify it as `--type=NodePort`
        - `--name=$SERVICE_NAME`: Name of the service
        - `--port=$PRIVATE_PORT`: Specify a private (internal) port
    - (CAUTION) with `expose` command, u can’t set the public (external) port → It’s assigned randomly
    - Examples
        
        ```bash
        kubectl expose deployment dpy-nginx --type=NodePort --name=np-svc --port=80 # Link deployment "dpy-nginx" with NodePort
        ```
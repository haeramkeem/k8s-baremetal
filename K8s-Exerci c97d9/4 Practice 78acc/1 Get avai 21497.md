# 1. Get available nodes and objects

1. `kubectl get nodes`
    - Show all information for node
    - `-o $OPTIONS`: Specify the options
        - `wide`: Show additional information for each pod
    - Examples
        
        ```bash
        kubectl get nodes # Show nodes in default columns
        Kubectl get nodes -o wide # Show nodes in extended columns
        ```
        
2. `kubectl get pods`
    - Show all information for pods
    - `-n $NAMESPACE`: Specify the namespace for the pods → Default is the *default namespace*
    - `-o $OPTIONS`: Specify the options
        - `wide`: Show additional information for each pod
        - `-o=custom-columns=$HEADER:$JSON_PATH_EXPR`: Show information in custom column
            - Custom column example
                
                ```bash
                kubectl get pods -o=custom-columns=\
                NAME:.metadata.name,\
                IP:.status.podIP,\
                STATUS:.status.phase,\
                NODE:.spec.nodeName
                ```
                
    - Examples
        
        ```bash
        kubectl get pods # Show pods for the default namespace
        kubectl get pods -n kube-system # Show pods for the Kubernetes system pods
        kubectl get pods -o wide # Show pods with additional information
        ```
        
3. `kubectl get services`
    - Show all information for services
    - Examples
        
        ```yaml
        kubectl get services # Show services
        ```
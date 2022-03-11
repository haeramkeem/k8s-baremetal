# 2. Create an object

1. `kubectl create $OBJECT $OBJ_NAME [$ARGS]`
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
        
2. `kubectl run $POD_NAME [$ARGS]`
    - This is how to make a pod with no *object spec file*
        - This command creates only one pod, so u can’t scale it dynamically
    - `--image=$IMAGE`: Specify the image of the pod
    - Examples
        
        ```bash
        kubectl run nginx-pod --image=nginx # Create nginx pod with a specified image
        ```
        

## Example of the object spec file

- Pod
    
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-pod
    spec:
      containers:
      - name: container-name
        image: nginx
    ```
    
- Deployment
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: dpy-nginx
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: deployment-name
            image: nginx:latest
    ```
# 3. Modify an object

1. `kubectl scale $OBJECT $OBJECT_NAME`
    - Modifies running object
    - (CAUTION): U can’t scale a pod with this command; If u make a pod with *run* command, using *scale* command will generate this error: `Error from server (NotFound): the server could not find the requested resource`
    - `--replicas=$NUMBER`: Specify the number of pods running on the objects
    - Examples
        
        ```bash
        kubectl scale deployment dpy-nginx --replicas=3 # Modify the number of pods in the "dpy-nginx" deployment
        ```
        
2. `kubectl apply -f $FILEPATH`
    - Create or modify an object based on *object spec*
    - MUST specify the path of *object spec* *file (JSON, YAML or URL)*
    - U can modify an object that is created with `kubectl create` command, but it’s not recommended
        - So, if u wanna make an object that has the possibility of change, use `kubectl apply` command instead
    - `--record`: Record history option
    - Examples
        
        ```bash
        kubectl apply -f ./dpy-nginx.yaml # Create or modify an object based on "dpy-nginx.yaml" object spec file
        ```
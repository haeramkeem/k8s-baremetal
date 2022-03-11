# 7. How to track history, update a pod, and rollback to prev state

- Kubernetes updates the pods in an object sequentially → It’s called **rollout**
    - So, `rollout` command helps u to manage the modification of an obect and its pods
    - But, to keep track of the modification, u have to use `--record` option every time u modify deployment’s status
        - Example
            
            ```bash
            kubectl apply -f ./dpy-nginx.yml --record # Record creation (or modification)
            ```
            
    - `kubectl rollout history $OBJECT $OBJECT_NAME`: Print object history
        - Each previous state is represented as **revision**
        - Example
            
            ```bash
            kubectl rollout history deployment dpy-nginx # Print rollout history
            ```
            
    - `kubectl rollout status $OBJECT $OBJECT_NAME`: Print rollout status
        - Example
            
            ```bash
            kubectl rollout status deployment dpy-nginx # Print rollout status
            ```
            
- To update an image of the pods in an object, use `set image` command
    - `kubectl set image $OBJECT $OBJECT_NAME $OLD_IMAGE:$NEW_IMAGE`
        - Example
            
            ```bash
            kubectl set image deployment dpy-nginx nginx=nginx:1.16.0 # Modify image of the "dpy-nginx" to version "v1.16.0"
            ```
            
- To undo the rollout, use `rollout undo` command
    - `kubectl rollout undo $OBJECT $OBJECT_NAME`: Rollback to the previoud state
        - `--to-revision=$REVISION_NUMBER`: Rollback to specific revision
    - Example
        
        ```bash
        kubectl rollout undo deployment dpy-nginx # Rollback deployment "dpy-nginx" to the previous version
        kubectl rollout undo deployment dpy-nginx --to-revision=2 # Rollback deployment "dpy-nginx" to the revision 2
        ```
        
- `describe` command provides detailed information for a given object
    - `kubectl describe $OBJECT $OBJECT_NAME`
    - Example
        
        ```bash
        kubectl describe deployment dpy-nginx # Print detail information for deployment "dpy-nginx"
        ```
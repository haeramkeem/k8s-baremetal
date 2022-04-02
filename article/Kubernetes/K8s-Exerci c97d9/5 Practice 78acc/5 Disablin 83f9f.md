# 5. Disabling scheduling

- For some cases like the problem of nodes, Kubernetes provides functionality for disabling further scheduling
- This is useful when some nodes have problems but u have to use that node to prevent ur service from shut down
    - In this case, u can limit the node to disable further scheduling while existing pods are still running
- `cordon` and `uncordon` commands are to support this functionality
- `kubectl cordon $NODE_NAME`: Disable scheduling for a given node
- `kubectl uncordon $NODE_NAME`: Enable scheduling for a given node
- Demo
    - Current status for `node01`’s pods:
    
    ![Untitled](5%20Disablin%2083f9f/Untitled.png)
    
    - Disable scheduling for `node01`:
    
    ```bash
    kubectl cordon node01 # Disable scheduling
    ```
    
    - Status for `node01` → `kubectl get nodes`
    
    ![Untitled](5%20Disablin%2083f9f/Untitled%201.png)
    
    - Scale deployment to see what happens → `kubectl scale`
    - Result of scaling: created pods are pended → cuz `node01` is disabled and no other nodes are available
    
    ![Untitled](5%20Disablin%2083f9f/Untitled%202.png)
    
    - Enable scheduling for `node01`:
    
    ```bash
    kubectl uncordon node01 # Enable scheduling
    ```
    
    - Result of enabling: pods are scheduled to `node01`
    
    ![Untitled](5%20Disablin%2083f9f/Untitled%203.png)
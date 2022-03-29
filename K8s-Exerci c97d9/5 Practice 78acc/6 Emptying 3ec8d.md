# 6. Emptying a node

- In some times like u have to upgrade ur machine for a node, u have to move all the pods for the node to another node
- To support this, Kubernetes supports command `drain`
- `kubectl drain $NODE_NAME`: Emptying a given node
    - `--ignore-daemonsets`: When u use this command without this option, the command will be aborted → cuz daemons are running on the node
    - So, u have to use this option when u use `drain` command
- Demo
    - Current status for `node01`:
    
    ![Untitled](6%20Emptying%203ec8d/Untitled.png)
    
    - Empty a node `node01`
    
    ```bash
    kubectl drain node01 --ignore-daemonsets
    ```
    
    - Result: all the pods are pended cuz `node01` is emptied and no other nodes are available
    
    ![Untitled](6%20Emptying%203ec8d/Untitled%201.png)
    
    - Status of the `node01` → `kubectl get nodes`
    
    ![Untitled](6%20Emptying%203ec8d/Untitled%202.png)
    
    - Enable scheduling by `kubectl uncordon`
        - (CAUTION): there are no such a command like “kubectl undrain”
        - U have to use `kubectl uncordon` if u wanna cancel the draining
    - Status after enabling:
    
    ![Untitled](6%20Emptying%203ec8d/Untitled%203.png)
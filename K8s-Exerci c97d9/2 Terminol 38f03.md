# 2. Terminology

- Container
    - Process for one or more purposes running on an isolated execution environment
- Pod
    - Group of one or more Docker containers with shared namespaces, shared filesystem volumes, and a specification for how to run the containers
    - Smallest deployable units of computing that you can create and manage in Kubernetes
    - When a pod consists of a single container, u can think of it as a **wrapper of a container**
        - Integrate one or more application containers that are relatively tightly coupled to serve a single cohesive (closely united) unit of service - “Logical Host”
    - And when a pod consists of multiple containers, it is kinda **capsule of the containers**
        - These containers are co-located on a single “Node”
        - And they are co-managed
        - Also, they are activated in a synchronized way → This is called *co-scheduling*
        - The containers can share resources and dependencies, communicate with one another, and coordinate when and how they are terminated
        - Example for multi-container pod
            
            One container serves data stored in a shared volume to the public, while a separate *sidecar* container refreshes or updates those files. The Pod wraps these containers, storage resources, and an ephemeral network identity together as a single unit.
            
        - Along with the application containers, *init container* and *ephemeral (temporary) container → for debugging* can be integrated into the pod
        - Kubernetes does not directly manage the container; It controls the **pod** instead of each container
    - Think about pods this way: Most of the pods are just wapping a container, but not all pods does that
    - A Pod is just a logical thing → the concept of “wrapper” of the container makes u feel like a Pod is stored in the worker node (in the logical perspective, it’s correct), but a Pod is stored in a master node in physical perspective
        - But u can think that a Pod is stored in the worker node → It doesn’t matter where a pod is actually stored
- Node
    - Node is a physical (or virtual) machine (computer)
- Workload resources and Controller
    - Creating pods directly is not common; They are usually created under workload resources
    - So, **Workload resource** is kinda set of identical (of course, it is not 100% identical) pods
    - And watching and managing each workload resource is what **Controller** does
    - Pods that are located in a single workload resource has the same **PodTemplate**; In other words, Controller automatically creates pods for the workload resource using the **PodTemplate**
        - So, u can think of it as How to create each pod for the workload resource
        - Also, u can think of it as the Desired state of each pod for the workload resource
        - So, when the pod template of one workload resource is changed, all the pods inside it are re-created based on that pod template
        - U can specify How to update each pod when replacing
- Kubelet
    - An agent that runs on each node in the cluster. It makes sure that containers are running in a pod
    - This agent manages the controllers and pods for the node
    - So, when Kubelet doesn’t work, creating and deleting the pods will not be working either
- Kubectl
    - This agent provides Command Line Interface (CLI) to control the Kubernetes cluster
    - It uses the Kubernetes API Server, so installing Kubectl to the master node (where API Server is installed) would be nice
- Container Runtime Interface (CRI)
- Kubernetes API Server
    - All the commands to the Kubernetes go through the API Server
    - Even Kubectl works with the help of API Server
    - So, u can think of it as an interface that provides controlling the Kubernetes cluster
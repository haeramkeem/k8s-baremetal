# 3. Mechanism

## The basic principle

- The basic principle for Kubernetes is a **state-based**, **declarative structure**
- So, when the state has been changed, all the related components will struggle to fit in that state
- That is the meaning of the declarative structure: when the user **declares** the **state,** then the changes will happen automatically, not the way the user has to tell Kubernetes how to.
- Rough flow is as follows:
    1. User changes the state with the help of API Server (or through the Kuberctl)
    2. API Server watches the change of the components
    3. Components find the change of the state
    4. Components try to fit in the changed state

## Structure

- The overall structure for the Kubernetes cluster consists of one master node and one or more worker nodes
- **Master node**: This node manages all the worker nodes
    - API Server (+ Kubectl), Controller, and Scheduler are usually installed
    - Where state of the Kubernetes cluster is saved
- **Worker node**: This is where all the computing things happen
    - Many pods and containers are activated according to the state of the master node

## Pod life cycle

- According to the basic principle, the life cycle of the pod from creation to destroy is as follows:
1. User requests the creation of the pod to the API Server (or through the Kuberctl)
2. (Not only this time - every time when the components are updated) API Server saves the update (includes the state) to the `etcd`
3. API Server watches the controller → The controller creates the pod (but does not decide which node to store)
4. API Server watches the scheduler → The scheduler decides which worker node to store
5. API Server watches the scheduled worker node’s Kubelet
6. Requested Kubelet creates the container with the help of CRI(Container Runtime Interface)
7. Kubelet sends the state of the created pod to the API Server
8. The pod is available
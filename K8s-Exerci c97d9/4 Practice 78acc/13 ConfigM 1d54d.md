# 13. ConfigMap

## About ConfigMap

- The **ConfigMap** is simple; It’s like a *global configuration node* in *Node-RED*
- That is, **ConfigMap** contains the configurations for specific object
- Thus, when **ConfigMap** is changed (like when using `kubectl apply -f`), configurations for that object are also changed
- But modified configurations are applied after the pods for that object are recreated → so u have to delete the pods to recreate
- Note that for some objects, they got their own configuration object; For example, for *Ingress controller*, `Ingress` object is used to configure

## Demo

- See .sh file to figure out the demo:
    
    https://github.com/haeramkeem/k8s-exercise/blob/f0cd932d19902cca5177f147373e63e8baac75f0/ch3/3.4.2-ConfigMap/configmap-demo.sh
    
- Live demo:
    
    ```bash
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/ch3/3.4.2-ConfigMap/configmap-demo.sh)
    ```

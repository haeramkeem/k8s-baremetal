# 1. VirtualBox and Vagrant

## Setting environment

1. Install Virtual Box 6.1.12
    
    [Download_Old_Builds_6_1 - Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Download_Old_Builds_6_1)
    
1. Install Vagrant
    
    [Vagrant by HashiCorp](https://www.vagrantup.com/)
    
1. Initiate virtual cluster with Virtual Box and Vagrant
    
    ```bash
    bash <(curl -sL https://raw.githubusercontent.com/haeramkeem/k8s-exercise/main/self/env.sh)
    ```
    

## Vagrant command

1. Initiate directory → this will make `Vagrantfile` which contains the configuration of the virtual environment
    
    ```bash
    vagrant init
    ```
    
2. Prepare and initiate virtual environment
    
    ```bash
    vagrant up
    ```
    
3. SSH connect to the certain virtual machine
    
    ```bash
    vagrant ssh $VIRTUAL_MACHINE_NAME
    ```
    
4. Destroy the virtual environment
    
    ```bash
    vagrant destroy -f
    ```
    
5. Suspend vm
    
    ```bash
    vagrant halt
    ```
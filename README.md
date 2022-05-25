# ClusterMaker
K8s cluster VM setup automation tools

## Prerequisites

As a VM provisioning tool, `Vagrant` must be installed on your host machine

And as a VM provider, `VirtualBox` must be installed on your host machine

## Index

- online-cluster/ : Online K8s cluster makers
    - centos-7/ : CentOS 7 based K8s cluster maker
    - ubuntu-20.04/ : Ubuntu 20.04 LTS based K8s cluster makers
        - high-available/ : Highly-Available controlplane setup
        - external-IC/ : External HAProxy IC frontend setup
- offline-cluster/ : Offline K8s Cluster makers
    - centos-7/ : CentOS 7 based K8s cluster maker
    - ubuntu-20.04/ : Ubuntu 20.04 LTS based K8s cluster makers
        - high-available/ : Highly-Available controlplane setup
        - minimum/ : K8s cluster w/ minimum setup
        - docker-registry/ : K8s cluster w/ Docker Registry setup
- offline-app-installer/ : Offline K8s application installer packs

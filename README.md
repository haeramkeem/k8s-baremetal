# Kubernetes Infrastructure as Code

This repository contains:

1. K8s cluster VM setup automation tools (IaC)
2. Demos for the Kubernetes and Docker

## Prerequisites

- `VirtualBox` : VM provider
- `Vagrant` : VM provisioner

## Index

- demo/ : K8s demonstration scripts
- online-cluster/ : Online K8s cluster makers
    - centos-7/ : CentOS 7 based K8s cluster maker
    - rocky-8.6/ : Rocky linux 8.6 based K8s cluster maker
    - ubuntu-20.04/ : Ubuntu 20.04 LTS based K8s cluster makers
        - high-available/ : Highly-Available controlplane setup
        - haproxy-ingress-controller-external-example/ : External HAProxy IC frontend setup
- offline-cluster/ : Offline K8s Cluster makers
    - centos-7/ : CentOS 7 based offline K8s cluster maker
    - rocky-8.6/ : Rocky linux 8.6 based offline K8s cluster maker
        - high-available/ : Highly-Available controlplane setup
        - minimum/ : K8s cluster w/ minimum setup
    - ubuntu-20.04/ : Ubuntu 20.04 LTS based offline K8s cluster makers
        - high-available/ : Highly-Available controlplane setup
        - minimum/ : K8s cluster w/ minimum setup
- offline-app-installer/ : Offline K8s application installer packs
    - external-HAProxy-IC/ : External HAProxy IC migrator
    - HA-PostgreSQL/ : Highly-available PostgreSQL downloader & installer
    - HA-redis/ : Highly-available Redis downloader & installer
    - HA-harbor/ : Highly-available Harbor image registry downloader & installer
    - loki-stack/ : Loki stack (PLG) downloader & installer
    - nfs-subdir-external-provisioner/ : NFS external PV provisioner downloader & installer
    - docker-registry/ : Basic docker registry downloader & installer

# 1. Container Infrastructure

## IaaS

- **On-premises**: Infrastructure where the developer has to install all the dependencies manually
- **Infrastructure as a Service(IaaS)**: Service that provides ready-to-go infrastructure

## Monolithic VS MSA

- **Monolithic Architecture**: Architecture where all the features are integrated into a single service to form an application
    - Pros: (1) Easy to design, develop, and manage (2) Fast
    - Cons: (1) Limitations on scaling (2) Increment of coupling
- **Micro-Service Architecture**: Architecture where each feature is built as a service (= Micro-Service) and all the services are connected to form an application
    - Pros: (1) Reusable (2) Scalable (3) Low coupling
    - Cons: (1) Difficult to configure (2) Performance issue due to communication between microservices

## Container Infrastructure

![Source: Kubernetes official documentation](1%20Containe%20fb1bc/Untitled.png)

Source: Kubernetes official documentation

- Traditional Deployment: All the applications are running on the same OS and HW
    - This is kinda *Monolithic Architecture*
- Virtualized Deployment: Each service is running on the *virtual machines*, and these *virtual machines are running* on the same hypervisor, OS, and HW
    - This is kinda early version of the *MSA*
    - But this is very inefficient cuz each virtual machine has its own OS
- Container Deployment: Each service is running on the **containers** instead of the *virtual machines*
    - This is what recent *MSA* looks like
    - As each **container** shares the kernel of the host OS, each service runs lighter than when running on the *virtual machines*

## Introducing Kubernetes

- In 2014, *Google* contributed its own Container Orchestration System to the open-source community → The name of the system is **Kubernetes**
- By the concept of a *Pod*, Kubernetes provides more abstracted management solution other than container or computing machine
- Thus, **Kubernetes** makes it possible for users where users don’t have to concern much about container or machine
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

## Tools

1. **Docker**: Container distribution platform
2. **Kubernetes**: Container orchestration system
3. **Jenkins**: CI (Continous Integration) and CD (Continous Deployment)
4. **Prometheus & Grafana**: Monitoring & Dashboard
5. **Kubeadm**: Kubernetes installation tool
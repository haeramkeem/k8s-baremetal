# 1. About Docker

## Background

![Docker env structure (1).png](1%20About%20Do%209b7d0/Docker_env_structure_(1).png)

- The Linux operating system originally supports the **Containers**
- The **Container** is the package of application code and its overall dependencies
- The *overall dependencies* include the execution environment; This is a very powerful feature for containers cuz all the containers are isolated from other containers
- So, all the containers have their own system resources so that each application in a container can’t take other application’s resources
- Furthermore, It makes developers predict how the application *exactly* works
- The problem is the configuration for the containers are very difficult so that only skilled developers can use those feature
- However, Docker Inc. releases its solution for solving this problem in 2013
- Docker makes creating containers easier and provides CLI so that developers can manage the containers by commands
- Also, Docker makes industrial standards for containers to make containers portable and able to run exactly the same way regardless of the running environment

## Image and Container

![Group 27.png](1%20About%20Do%209b7d0/Group_27.png)

- **Image** is kinda template for the container
- It can’t be executed by itself, but it has to be a container for executing it
- The CRI (Container Runtime Interface) takes an Image and creates a container with that image
    - Docker has its own CRI; Docker splits its CRI and makes it open-source → It’s called  *ContainerD*
- After the container is created, they consume additional disk storage too
    - So u have to delete the container *and* image when u want to delete them cleanly
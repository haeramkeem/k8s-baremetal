# 2. Structure for Docker

![Docker structure (1).png](2%20Structur%200dc8d/Docker_structure_(1).png)

## Docker Engine

- Docker Engine helps developers containerizing their applications
- It acts as one of the client-server models:
    - **Docker Daemon** (`dockerd`) acts as a server for managing the containers
    - **Docker API** provides API which provides user or other applications interface of the Docker Daemon
    - **Docker CLI** is the command-line interface for the user → It translates and sends the command to the Docker API to control the containers

## Image Registry

- **Image Registry** is a platform where users of the docker can share and download images
- For Docker, **Docker Hub** is officially supported Image Registry
- But u don’t have to use them → Many other Image Registries are in the market, and u can make on ur own Image Registry
    - It’s useful when u don’t want ur image to be shown publically (for some cases like usage of the company) and when docker is installed in the intranet environment, not the *internet* environment
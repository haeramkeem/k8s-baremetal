# 4. About Containers

## Container Port

![Port forwarding (1).png](4%20About%20Co%2019af3/Port_forwarding_(1).png)

- Port of the container is inaccessible from the outside; cuz the containers are running *on* the host machine
- So if u want to access a certain port from the outside of the container, u have to connect it with the port of the host
    - This is done with `-p` option when u run the container
    - More information about `-p` option is in practice chapter
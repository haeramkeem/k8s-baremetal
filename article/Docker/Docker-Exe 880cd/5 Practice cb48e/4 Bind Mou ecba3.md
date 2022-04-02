# 4. Bind Mount and Volume

## Copy file to Docker container

- `docker cp $HOST_PATH $CONTAINER_NAME:$CONTAINER_PATH`
    - Copy a file that exists on `$HOST_PATH` to `$CONTAINER_PATH` of the `$CONTAINER_NAME`
    - As this command is just for copying the files, recommended usage is when u want to copy the temporary file to the container
    - Example
        
        ```bash
        docker cp /root/index.html nginx-container:/usr/share/nginx/html/index.html # Copy 'index.html' to the container "nginx-container"
        ```
        

## Bind Mount

- The **Bind Mount** is overlapping the directory of the host to the directory of the container
    - Note that this command **overlaps** the directory of the container
    - So, existing files will be overlapped when u use the bind mount
- This feature doesn’t require an additional job; U can use this by just specifying both directories with `-v` option when u run the container
- `docker run -v $HOST_DIR:$CONTAINER_DIR ...`
    - Example
        
        ```bash
        docker run -d -p 8080:80 -v /root/html:/usr/share/nginx/html nginx # Run Nginx container with bind mount /root/html to /usr/share/nginx/html of the container
        ```
        

## Volume

- The **Volume** is synchronizing the directory of the host to the directory of the container
    - So, unlike the *Bind Mount*, the files in the container directory are not overlapped
    - Instead, the files in the container directory and host directory will be the same when u use the **Volume** → This is what ‘*synchronizing*’ means
- U have to make volume before using it with the `docker run` command
    - `docker volume create $VOLUME_NAME`: Create volume
    - `docker volume inspect $VOLUME_NAME`: Print the spec of the volume
    - Example
        
        ```bash
        docker volume create nginx-volume # Create a volume named "nginx-volume"
        docker volume inspect nginx-volume # Print the spec of the "nginx-volume" volume
        ```
        
- After u create the volume, u can use it with `docker run` command
    - Like the usage of the Bind Mount, using `-v` option will make the container to use that volume
    - `docker run -v $VOLUME_NAME:$CONTAINER_DIR ...`
        - Example
            
            ```bash
            docker run -d -p 8080:80 -v nginx-volume:/usr/share/nginx/html nginx # Run Nginx container with volume "nginx-volume"
            ```
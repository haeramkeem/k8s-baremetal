# 3. Running Containers

## Running Container

- `docker run [$OPTION] $IMAGE`
    - Options:
        - `-p $EXT_PORT:INT_PORT`: Expose the port of the container to the outside
        - `-d` or `--detach`: Running containers in the background
            - Unless the container is not running in the background, all the logs will be shown in STDOUT, and using `ctrl+c` to exit to the shell will stop the container too
        - `--name $CONTAINER_NAME`: Specify the name of the container
        - `--restart $ARG`: Specify the restart policy → default value is `no`
            
            
            | $ARG | When the container fails | When the Docker is initiated |
            | --- | --- | --- |
            | no | Do not restart | Do not start the container |
            | on-failure | Restart | Start |
            | always | Restart | Start |
            | unless-stopped | Restart | Start the container that the user didn’t stop |
    - Example
        
        ```bash
        docker run -d --restart always nginx # Run Nginx container on the background and always restart the container when either container fails and docker is initiated
        docker run -d -p 8080:80 nginx --name nginx-container # Run Nginx container whose port 80 is linked with the external port 8080 and name is specified with "nginx-container"
        ```
        
        - Result:
            
            ![Untitled](3%20Running%20%20050ea/Untitled.png)
            
            - When a container starts running, ID of the container will be printed on the STDOUT

## Show Containers

- `docker ps [$OPTION]`
    - Show all the containers → `ps` means ‘process status’
    - Option:
        - `-a`or `--all`: Show all the containers including stopped container
        - `-q` or `--quiet`: Show the container ID only
        - `-f $CONDITION` or `--filter $CONDITION`: Filter the result by given condition
            - Most frequent `$CONDIION`:
                1. `id=$ID`: ID of the container
                2. `name=$CONTAINER_NAME`: Name of the container
                3. `label=$CONTAINER_LABEL`: Label of the container
                4. `status=$CONTAINER_STATUS`: Status of the container
                5. `ancestor=$IMAGE`: Image of the container
    - Result exaplanation:
        
        ![Untitled](3%20Running%20%20050ea/Untitled%201.png)
        
        - *Container ID*: Part of the container ID (digest)
        - *Image*: Image for that container
        - *Command*: Show which command was executed when container is initiated
        - *Status*: Age of the container
        - *Ports*: Port linkage of the container
        - *Names*: Name of the container
    - Example
        
        ```bash
        docker ps -a # Show all the containers to the STDOUT
        docker ps -f ancestor=nginx # Show all the containers that are created based on "Nginx" image
        ```
        

## Executing Command on the Container

- `docker exec [$OPTION] $CONTAINER $COMMAND`
    - Execute the given command in the specified container
    - Options
        - `-i` or `--interative`: Keep STDIN open even if a command is not running on attach mode
        - `-t` or `--tty`: Allocate a pseudo-TTY (kinda shell → i donno)
    - Examples
        
        ```bash
        docker exec -it nginx-container /bin/bash # Execute bash shell of the "nginx-container" container
        docker exec nginx-container ls # Execute 'ls' command in "nginx-container" container
        ```
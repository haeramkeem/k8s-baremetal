# 5. Image and Container Clean up

## Stopping Container

- `docker stop $CONTAINER`
    - In the `$CONTAINER` part, u can use the container name and part of the container id
    - When u want to stop multiple containers, it’s better to use this with `docker ps` command
        - As `docker ps -aq -f $CONDITION` command will print the IDs of the multiple containers, utilizing it with `$()` feature will help u to stop multiple containers
    - Example
        
        ```bash
        docker stop $(docker ps -aq -f ancestor=nginx) # Stop all the containers which are created with Nginx image
        ```
        

## Deleting Container

- `docker rm [$OPTION] $CONTAINER`
    - `-f` or `--force`: Force deletion of the containers
- To delete the running container, u have to stop it beforehand
    - So, u have to use the `docker stop` command before using the `docker rm` command
    - But, u can delete the container when u use force deletion → `docker rm -f` command doesn’t require the stopping of the container
    - However, force deletion is not recommended because of the possibility of the side-effects
- Like in the case of stopping the containers, combining `docker ps` command with `docker rm` command helps u to delete multiple containers
    - Example
        
        ```bash
        docker rm $(docker ps -aq -f ancestor=nginx) # Delete all the containers which are created with Nginx image
        ```
        

## Deleting Image

- `docker rmi $IMAGE`
    - Combining this command with `docker ps` command also helps u to delete the images
    - Example
        
        ```bash
        docker rmi $(docker ps -q nginx) # Delete all the images which are related to Nginx
        ```
# 1. Searching and Pulling an Image

## Searching

- `docker search $KEYWORD`
    - Search the images that contain `$KEYWORD` from the image registry
        - U can add the tag with `:` mark
    - If the registry is not specified, the images are searched in the Docker Hub by default
    - The result image and explanation are shown below:
        
        ![Untitled](1%20Searchin%2091450/Untitled.png)
        
        - *Name*: Name of the searched image → Unless it is the official image, the format of the name is like `$REGISTRY/$IMAGE_NAME`
        - *Description*: Description for the image
        - *Star*: Stars that are given to the image
        - *Official*: Whether it is the official image
        - *Automated*: Whether the image is created by automated image build that Docker Hub supports
    - Example
        
        ```bash
        docker search nginx:stable # Search stable version of the Nginx image
        ```
        

## Pulling

- `docker pull $IMAGE_NAME:$IMAGE_TAG`
    - Download (pull) an image from the image registry
    - When the `$IMAGE_TAG` is not specified, the ‘latest’ tag is used by default
    - Example
        
        ```bash
        docker pull nginx # Pull the latest version of the Nginx image
        ```
        
        - Result:
            
            ![Untitled](1%20Searchin%2091450/Untitled%201.png)
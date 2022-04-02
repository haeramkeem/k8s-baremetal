# 3. About Image

## Metadata for Image

![Image meta (1).png](3%20About%20Im%2084115/Image_meta_(1).png)

- Every image has a **Status** and **Digest**
- **Status** consists of 3 values: **Repository**, **Name**, and **Tag**
    - **Repository** is where an image is stored
    - **Name** is the name of the image
    - **Tag** is an additional value for platform, version, *etc*
- **Digest** is the SHA-256 hash of the image manifest and is used as an identifier for the image

## Image Layer

![Image layer.png](3%20About%20Im%2084115/Image_layer.png)

- Every image contains the applications and files → And they are grouped as **Layer**
- These **Layer**s are shared over the images so that docker can reduce the size of the image
    - When u pull an image from the image registry, u can see that the duplicated layers are not downloaded
        
        ![Untitled](3%20About%20Im%2084115/Untitled.png)
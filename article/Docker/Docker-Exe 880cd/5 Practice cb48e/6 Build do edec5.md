# 6. Build docker image

## Dockerfile

- Making a `Dockerfile` is like this:
    1. Get a base image
    2. Copy the executable file to the image
    3. Specify the shell command which will be executed when an image is on the run
- As a result, a new image is built by adding a new layer to the base image, and the specifying command will be executed when an image is on the run

```bash
FROM openjdk:8 # Base Image
LABEL description="Echo IP Java Application" # Description for the image
EXPOSE 60431 # Expose port number
COPY ./target/app-in-host.jar /opt/app-in-image.jar # Copy executable file to the image
WORKDIR /opt # Change working dir to `/opt`
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ] # Run this command when an image is on the run
```

- `FROM`: As the docker images are built from base images, u have to specify what image u want to use
    - When u build a docker image, what u exactly do is adding the layers to the base image → This is why u need a base image for building an image
- `EXPOSE`: Unlike what it looks like, it’s just a **description** of which port u want to expose
    - U have to link this port with the host’s port by using the `-p` option when u run this image
- `WORKDIR`: This is similar to the `cd` command of bash shell
- `ENTRYPOINT`: This is the command which will be executed when an image is on the run
    - Format for the `ENTRYPOINT` is like splitting the command with space
    - So, the example `ENTRYPOINT` shown above is same as `java -jar app-in-image.jar`
- Other commands
    
    ```bash
    RUN ls -al # Run shell command
    ```
    
    - `RUN`: Run a bash shell command

## Optimization 1: Use a lighter base image

- Some base images contain the development tools as well as the execution environment
- But, we don’t need ‘em to run the images
- So using the lighter image is another way to optimize the size of the image
- As for Java, `gcr.io/distroless/java:8` can be one choice for the base image

## Troubleshoot: Build executable file inside of the image

- Building an executable file inside of the base image is the worse way to build an image
- Cuz all the development tools, the requiring dependencies, the generated cache will be left in the image

![Untitled](6%20Build%20do%20edec5/Untitled.png)

- So, as in the picture above, building an executable file inside of the image has the largest size among all the images

## Optimization: Multi-stage build

- The multi-stage building is like:
    1. Build an executable file inside of the dangling image (temporary image)
    2. Copy the executable file from the dangling image to the output image
    3. Build an actual image using that executable file 

```bash
# Dangling image for building
FROM openjdk:8 AS int-build # Set `int-build` as the alias of the dangling image
LABEL description="Java Application builder"
RUN git clone https://github.com/iac-source/inbuilder.git
WORKDIR inbuilder
RUN chmod 700 mvnw
RUN ./mvnw clean package

# Actual output image
FROM gcr.io/distroless/java:8
LABEL description="Echo IP Java Application"
EXPOSE 60434
COPY --from=int-build inbuilder/target/app-in-host.jar /opt/app-in-image.jar # Use `--from=$ALIAS` option to specify the path of the executable file
WORKDIR /opt
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
```

- The key point of the multi-stage build is the `--from=$ALIAS` option
    - That option lets u to copy the file inside of the dangling image, not the host
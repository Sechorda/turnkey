# This script is to pull down a toolkit
#!/bin/bash

# -
sudo apt update &> /dev/null
sudo apt upgrade &> /dev/null

# Check if docker command is available
if command -v docker &> /dev/null; then
    echo "Docker is already installed."
else
    # Docker not found, attempt installation
    echo "Docker not found. Attempting to install..."

    # - Stage Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm ./get-docker.sh

    # Check if installation was successful
    if command -v docker &> /dev/null; then
        echo "Docker installed successfully."
    else
        echo "Error: Docker installation failed."
        exit 1
    fi
fi


# - OWASP ZAP 
echo 'deb http://download.opensuse.org/repositories/home:/cabelo/xUbuntu_22.10/ /' | sudo tee /etc/apt/sources.list.d/home:cabelo.list
curl -fsSL https://download.opensuse.org/repositories/home:cabelo/xUbuntu_22.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_cabelo.gpg > /dev/null
sudo apt update
sudo apt install owasp-zap

docker pull caido/caido

# Check if caido/caido container is running
CAIDO_CONTAINER_NAME="caido"
CAIDO_IMAGE_NAME="caido/caido:latest"
CAIDO_HOST_PORT=7000

# Check if the container is already running
if docker ps | grep -q $CAIDO_CONTAINER_NAME; then
    # Get the container port mapping
    CAIDO_CONTAINER_PORT=$(docker port $CAIDO_CONTAINER_NAME 8080 | cut -d':' -f2)
    echo "Container $CAIDO_CONTAINER_NAME is already running on port $CAIDO_CONTAINER_PORT"
else
    # Run the Docker container in the background
    docker run -d --rm -p $CAIDO_HOST_PORT:8080 --name $CAIDO_CONTAINER_NAME $CAIDO_IMAGE_NAME

    # Check if the container is running after attempting to start it
    if docker ps | grep -q $CAIDO_CONTAINER_NAME; then
        # Get the container port mapping
        CAIDO_CONTAINER_PORT=$(docker port $CAIDO_CONTAINER_NAME 8080 | cut -d':' -f2)
        echo "Container $CAIDO_CONTAINER_NAME is now running on port $CAIDO_CONTAINER_PORT"
    else
        echo "Error: Failed to start container $CAIDO_CONTAINER_NAME."
        exit 1
    fi
fi

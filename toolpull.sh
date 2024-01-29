#!/bin/bash
SECONDS=0
require_sudo() {
    [ "$EUID" -eq 0 ] || { echo "Please run this script with sudo."; exit 1; }
}

update_system() {
    echo "Pulling tools!..."
    sudo apt update &> /dev/null
    sudo apt upgrade -y > /dev/null 2>&1
}

install_ffuf() {
    echo "Installing FFUF..."
    sudo apt install -y golang-go &> /dev/null
    cd ~ && go install github.com/ffuf/ffuf/v2@latest &> /dev/null
    sudo mv ~/go/bin/ffuf /usr/bin
    rm -rf ~/go
    echo "[+] FFUF is ready"
}

install_owasp_zap() {
    echo "Installing OWASP ZAP..."
    sudo apt install -y default-jre &> /dev/null
    sudo tee /etc/apt/sources.list.d/home:cabelo.list <<< 'deb http://download.opensuse.org/repositories/home:/cabelo/xUbuntu_22.10/ /' &> /dev/null
    curl -fsSL https://download.opensuse.org/repositories/home:cabelo/xUbuntu_22.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_cabelo.gpg > /dev/null
    sudo apt update &> /dev/null
    sudo apt install -y owasp-zap &> /dev/null
    echo "[+] OWASP-ZAP is ready"
}

install_docker() {
    if command -v docker &> /dev/null; then
        echo "[ ] Docker is already installed."
    else
        echo "Docker not found. Attempting to install..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh &> /dev/null
        command -v docker &> /dev/null && echo "[+] Docker is ready" || { echo "Error: Docker installation failed."; exit 1; }
    fi
}

install_caido() {
    wait_docker_installation
    echo "Containzerizing Caido..."
    docker pull caido/caido &> /dev/null

    CAIDO_CONTAINER_NAME="caido"
    CAIDO_IMAGE_NAME="caido/caido:latest"
    CAIDO_HOST_PORT=7000

    if docker ps | grep -q $CAIDO_CONTAINER_NAME; then
        CAIDO_CONTAINER_PORT=$(docker port $CAIDO_CONTAINER_NAME 8080 | cut -d':' -f2)
        echo "Container $CAIDO_CONTAINER_NAME is already running on port $CAIDO_CONTAINER_PORT"
    else
        docker run -d --rm -p $CAIDO_HOST_PORT:8080 --name $CAIDO_CONTAINER_NAME $CAIDO_IMAGE_NAME &> /dev/null
        
        if docker ps | grep -q $CAIDO_CONTAINER_NAME; then
            CAIDO_CONTAINER_PORT=$(docker port $CAIDO_CONTAINER_NAME 8080 | cut -d':' -f2)
            echo "[+] $CAIDO_CONTAINER_NAME is now ready on port $CAIDO_CONTAINER_PORT"
        else
            echo "Error: Failed to start container $CAIDO_CONTAINER_NAME."
            exit 1
        fi
    fi
}

wait_docker_installation() {
    # Wait until docker installation is finished
    while ! command -v docker &> /dev/null; do
        sleep 1
    done
}

main() {
    require_sudo
    (install_owasp_zap && install_ffuf && install_docker) &
    install_caido
    wait  # Wait for background tasks to finish
    echo "Elapsed Time (using \$SECONDS): $SECONDS seconds"
}

main

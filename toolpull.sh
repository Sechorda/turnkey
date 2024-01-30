#!/bin/bash

require_sudo() {
    [ "$EUID" -eq 0 ] || { echo "Please run this script with sudo."; exit 1; }
}

update_system() {
    echo "Pulling tools!..."
    sudo apt update &> /dev/null
    sudo apt upgrade -y > /dev/null 2>&1
}

download_files() {
    if ! command -v wget &> /dev/null; then
        sudo apt install wget
    fi

    mkdir -p sechordlist

    # Specify the URLs of the files you want to download
    file_urls=(
        "https://github.com/danielmiessler/SecLists/tree/master/Discovery/Web-Content/https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/common-api-endpoints-mazen160.txt"
        "https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/api/api-seen-in-wild.txt"
        "https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/api/api-endpoints.txt"
        "https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/api/actions.txt"
        "https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/burp-parameter-names.txt"
    )
    
    # Loop through the URLs and download each file
    for url in "${file_urls[@]}"; do
        filename=$(basename "$url")
        wget -c "$url" -O "sechordlist/$filename" &> /dev/null
    done
    echo "[+] API wordlists downloaded and stored in sechordlist folder."
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
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh &> /dev/null
        command -v docker &> /dev/null && echo "[+] Docker is ready" || { echo "Error: Docker installation failed."; exit 1; }
    fi
}

install_caido() {
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

main() {
    require_sudo
    update_system
    install_owasp_zap 
    install_ffuf
    install_docker
    install_caido
}

main

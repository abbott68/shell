#!/bin/bash

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update && sudo apt install -y gcc libpcre3-dev zlib1g-dev libssl-dev
}

# Function to download nginx source code based on version
download_nginx() {
    read -p "Enter Nginx version (e.g., 1.21.3): " nginx_version
    echo "Downloading Nginx version $nginx_version..."
    wget "http://nginx.org/download/nginx-$nginx_version.tar.gz"
    tar zxf "nginx-$nginx_version.tar.gz"
    cd "nginx-$nginx_version" || exit
}

# Function to compile and install nginx
install_nginx() {
    echo "Compiling and installing Nginx..."
    ./configure
    make
    sudo make install
    echo "Nginx installed successfully!"
}

# Main function to control the flow
main() {
    install_dependencies
    download_nginx
    install_nginx
}

# Execute the script
main

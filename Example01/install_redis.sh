#!/bin/bash

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update && sudo apt install -y build-essential tcl
}

# Function to download redis source code based on version
download_redis() {
    read -p "Enter Redis version (e.g., 6.2.6): " redis_version
    echo "Downloading Redis version $redis_version..."
    wget "http://download.redis.io/releases/redis-$redis_version.tar.gz"
    tar xvzf "redis-$redis_version.tar.gz"
    cd "redis-$redis_version" || exit
}

# Function to compile and install redis
install_redis() {
    echo "Compiling and installing Redis..."
    make
    make test
    sudo make install
    echo "Redis installed successfully!"
}

# Main function to control the flow
main() {
    install_dependencies
    download_redis
    install_redis
}

# Execute the script
main

#!/bin/bash

# docker_install.sh
# This script checks for existing Docker installation.
# If Docker is present, it prompts the user to keep it or replace it.
# If the user chooses to replace, it installs Docker from a provided tar.gz file.
echo ""
echo "---------------------------------------------------------------------------------------------------------------"
DOCKER_TAR="/home/sagar/Downloads/Docker/docker-installation/docker-27.4.1.tgz"
DOCKER_SERVICE_FILE="/home/sagar/Downloads/Docker/docker-installation/docker.service"

# Function to check if Docker is installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
        docker --version
        return 0
    else
        echo "Docker is not installed."
        return 1
    fi
}

# Function to remove existing Docker installation
remove_existing_docker() {
    echo "Removing existing Docker installation..."
    sudo systemctl stop docker
    sudo systemctl disable docker
    sudo rm -rf /usr/bin/docker* /etc/systemd/system/docker.service /etc/docker
    sudo rm -rf /var/lib/docker
}

# Function to install Docker from the tarball
install_docker_from_tar() {
    echo "Installing Docker from $DOCKER_TAR..."

    # Extract the Docker binaries
    tar -xvzf "$DOCKER_TAR" || { echo "Failed to extract $DOCKER_TAR"; exit 1; }

    # Move Docker binaries to /usr/bin/
    sudo mv docker/* /usr/bin/
    chmod -R 775 /usr/bin

    # Copy the service file to systemd and Docker directories
    sudo cp "$DOCKER_SERVICE_FILE" /etc/systemd/system/
    sudo mkdir -p /etc/docker
    sudo cp "$DOCKER_SERVICE_FILE" /etc/docker/
    chmod -R 775 /etc/docker

    # Reload systemd, start and enable Docker
    sudo systemctl daemon-reload
    sudo systemctl start docker
    sudo systemctl enable docker

    # Confirm Docker version
    docker --version || echo "Docker installation might have failed."
}

# Main script logic
check_docker_installed
if [ $? -eq 0 ]; then
    read -p "Do you want to remove the existing Docker and install a new one from tar? (yes/no): " choice
    if [[ "$choice" == "yes" ]]; then
        remove_existing_docker
        install_docker_from_tar
    else
        echo "Keeping existing Docker installation."
    fi
else
    install_docker_from_tar
fi

echo ""
echo "---------------------------------------------------------------------------------------------------------------"

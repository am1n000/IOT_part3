#!/bin/bash

sudo apt-get update

sudo apt-get upgrade -y

# Remove any existing Docker-related packages to ensure a clean installation
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install necessary dependencies for adding a new repository over HTTPS
sudo apt-get install ca-certificates curl gnupg lsb-release -y

# Create a directory for storing the GPG key securely with appropriate permissions
sudo mkdir -m 0755 -p /etc/apt/keyrings

# Download and add Docker's official GPG key to the keyring
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg -y

# Add the Docker APT repository to the system sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg]  \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Update package lists again to include the Docker repository
sudo apt-get update

# Install Docker components including Docker Engine, CLI, Containerd, Buildx, and Compose
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Create a Docker user group if it doesn't exist
sudo groupadd docker

# Add the current user to the Docker group to allow running Docker without sudo
sudo usermod -aG docker $USER

# Download and install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Download the latest stable version of kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl to /usr/local/bin with proper permissions and ownership
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

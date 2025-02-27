#!/bin/bash

# Color variables
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# Print a message in color
echo_color() {
    echo -e "$1$2$RESET"
}

# Step 1: Update the system
echo_color $CYAN "Updating the system..."
sudo apt-get update -y

# Step 2: Uninstall all conflicting packages
echo_color $YELLOW "Uninstalling all conflicting Docker packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc

# Step 3: Add Docker's official GPG key
echo_color $CYAN "Adding Docker's official GPG key..."
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 4: Add the repository to Apt sources
echo_color $CYAN "Adding Docker repository to Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5: Update the package index again
echo_color $CYAN "Updating package index after adding Docker repository..."
sudo apt-get update -y

# Step 6: Install Docker packages
echo_color $GREEN "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Final message
echo_color $GREEN "Docker installation complete!"
docker --version

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
echo_color $GREEN "Updating the system..."
sudo apt-get update -y

# Step 2: Install kubectl binary with curl
echo_color $GREEN "Install kubectl binary with curl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
 
# Step 3: Validate the binary 
echo_color $GREEN "Validate the binary..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

# Step 4: Validate the kubectl binary against the checksum file
echo_color $GREEN "Validate the kubectl binary against the checksum file..."
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Step 6: 
echo_color $GREEN "Install kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Step 7:
echo_color $GREEN "Check installed version"
kubectl version --client

# Final message
echo_color $GREEN "kubectl installation complete!"

alias k="kubectl"
alias n="namespace"

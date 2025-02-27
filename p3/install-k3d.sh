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

# Step 2: Uninstall all conflicting packages
echo_color $GREEN "install k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Final message
echo_color $GREEN "k3d installation complete!"
k3d --version

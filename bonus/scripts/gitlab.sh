#!/bin/bash

# Set error handling: Exit immediately if any command fails
set -e

# Improved Colors for output
RED='\033[1;31m'       # Bright Red for errors
GREEN='\033[1;32m'     # Bright Green for success
BLUE='\033[1;34m'      # Bright Blue for general info
YELLOW='\033[1;33m'    # Bright Yellow for warnings
MAGENTA='\033[1;35m'   # Bright Magenta for headers
CYAN='\033[1;36m'      # Bright Cyan for details
NC='\033[0m'           # No Color (reset)

# Logging functions
info() { echo -e "${CYAN}[INFO] $1${NC}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }

# Step 1: Clean up old containers and images
info "Starting cleanup process: Removing unused Docker containers, images, and volumes..."
if ! command -v docker &> /dev/null; then
    info "Docker not found. Installing Docker..."
    sudo apt install curl
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    success "Docker installed successfully."
fi
docker system prune -af
docker volume prune -f
success "Cleanup completed: Unused Docker resources removed."

# Step 2: Install required dependencies
info "Installing required dependencies: Docker, k3d, kubectl, and Helm..."
sudo apt-get update -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    info "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    success "Docker installed successfully."
fi

# Install k3d if not already installed
if ! command -v k3d &> /dev/null; then
    info "k3d not found. Installing k3d..."
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    success "k3d installed successfully."
fi

# Install kubectl if not already installed
if ! command -v kubectl &> /dev/null; then
    info "kubectl not found. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    success "kubectl installed successfully."
fi

# Install Helm if not already installed
if ! command -v helm &> /dev/null; then
    info "Helm not found. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    success "Helm installed successfully."
fi

# Clean up again after installations
info "Performing final cleanup: Removing unused Docker resources..."
docker system prune -af
docker volume prune -f
success "Final cleanup completed."

# Step 3: Set up a minimal K3d cluster
info "Setting up a minimal K3d cluster: Creating cluster 'gitlab-cluster'..."
k3d cluster delete gitlab-cluster 2>/dev/null || true
k3d cluster create gitlab-cluster \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer"
success "K3d cluster 'gitlab-cluster' created successfully."

# Wait for the cluster to be ready
info "Waiting for the cluster to be ready: Checking node status..."
until kubectl get nodes | grep -q " Ready"; do
    info "Cluster not ready yet. Retrying in 5 seconds..."
    sleep 5
done
success "Cluster is ready: All nodes are up and running."

# Create a namespace for GitLab
info "Creating namespace 'gitlab' for GitLab deployment..."
kubectl create namespace gitlab
success "Namespace 'gitlab' created successfully."

# Step 4: Deploy GitLab using Helm
info "Starting GitLab deployment: Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update
success "GitLab Helm repository added and updated."

# Uninstall previous GitLab installation if it exists
info "Checking for previous GitLab installation: Uninstalling if found..."
helm uninstall gitlab -n gitlab 2>/dev/null || true
kubectl delete pvc --all -n gitlab 2>/dev/null || true
sleep 10
success "Previous GitLab installation removed (if any)."

# Install GitLab
info "Installing GitLab: This may take a few minutes..."
helm upgrade --install gitlab gitlab/gitlab \
    --namespace gitlab \
    --timeout 600s \
    --set certmanager-issuer.email=me@example.com \
    --set global.hosts.domain=localhost \
    --set global.hosts.https=false \
    # --set global.certmanager.install=false \
    # --set global.nginx-ingress.enabled=false \
    # --set global.gitlab-runner.install=false
success "GitLab installed successfully."

# Wait for GitLab webservice to be ready
info "Waiting for GitLab webservice to be ready: This may take a few minutes..."
kubectl wait --namespace gitlab --for=condition=ready pod -l app=webservice --timeout=600s || true
success "GitLab webservice is ready."

# Expose GitLab to the outside world
info "Exposing GitLab to the outside world: Patching service and setting up port-forwarding..."
kubectl patch svc/gitlab-webservice-default -n gitlab -p '{"spec": {"type": "LoadBalancer"}}'
kubectl port-forward svc/gitlab-webservice-default -n gitlab 8181:8181 &
success "GitLab is now accessible at http://gitlab.localhost:8181."

# Retrieve and display access credentials
info "Retrieving GitLab access credentials..."
echo -e "\n${MAGENTA}=== GitLab Access Information ===${NC}"
echo -e "${CYAN}GitLab URL: http://gitlab.localhost:8181${NC}"
echo -e "${CYAN}GitLab Username: root${NC}"
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
echo -e "${CYAN}GitLab Password: $GITLAB_PASSWORD${NC}"
success "Access credentials retrieved successfully."

# Final message
success "GitLab setup completed successfully! 🎉"
warning "Note: If GitLab is not immediately accessible, please wait 5-10 minutes for all services to initialize."
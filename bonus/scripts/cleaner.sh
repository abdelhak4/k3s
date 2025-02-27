#!/bin/bash

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

# Step 1: Clean up GitLab resources
info "Starting GitLab cleanup process..."

# Delete GitLab Helm release
info "Deleting GitLab Helm release..."
helm uninstall gitlab -n gitlab 2>/dev/null || warning "GitLab Helm release not found or already deleted."

# Wait for GitLab pods to be deleted
info "Waiting for GitLab pods to be deleted..."
kubectl wait --for=delete pods --all -n gitlab --timeout=300s 2>/dev/null || warning "No GitLab pods found or already deleted."

# Delete GitLab namespace
info "Deleting GitLab namespace..."
kubectl delete namespace gitlab --timeout=300s 2>/dev/null || warning "GitLab namespace not found or already deleted."

# Delete any leftover PVs and PVCs
info "Deleting persistent volumes and claims..."
kubectl delete pv,pvc -l release=gitlab --force --grace-period=0 2>/dev/null || warning "No persistent volumes or claims found."

# Step 2: Clean up ArgoCD and dev namespaces
info "Deleting ArgoCD and dev namespaces..."
kubectl delete namespace argocd --timeout=300s 2>/dev/null || warning "ArgoCD namespace not found or already deleted."
kubectl delete namespace dev --timeout=300s 2>/dev/null || warning "Dev namespace not found or already deleted."

# Step 3: Clean up k3d cluster
info "Deleting k3d cluster..."
k3d cluster delete gitlab-cluster 2>/dev/null || warning "k3d cluster not found or already deleted."

# Step 4: Clean up Docker resources
info "Cleaning up Docker images and volumes..."
docker system prune -f --volumes
success "Docker system cleaned up."

# Step 5: Remove local directories
info "Cleaning up local directories..."
sudo rm -rf /var/lib/rancher/k3s/storage/gitlab* 2>/dev/null || warning "No GitLab storage directories found."
success "Local directories cleaned up."

# Step 6: Remove installed binaries
info "Removing installed binaries..."
sudo rm -rf /usr/local/bin/kubectl /usr/local/bin/helm /usr/local/bin/k3d 2>/dev/null || warning "No binaries found."
success "Binaries removed."

# Step 7: Remove configuration files
info "Removing configuration files..."
sudo rm -rf ~/.kube/config ~/.k3d ~/.local/share/k3d gitlab-values.yaml 2>/dev/null || warning "No configuration files found."
success "Configuration files removed."

# Step 8: Remove GitLab storage
info "Removing GitLab storage..."
sudo rm -rf /opt/gitlab* /var/opt/gitlab* /var/lib/docker/volumes/*gitlab* 2>/dev/null || warning "No GitLab storage found."
success "GitLab storage removed."

# Step 9: Remove hosts entry
info "Removing GitLab entry from /etc/hosts..."
sudo sed -i '/gitlab.localhost/d' /etc/hosts 2>/dev/null || warning "No GitLab entry found in /etc/hosts."
success "Hosts entry removed."

# Step 10: Verify cleanup
info "Verifying cleanup..."
echo -e "\n${MAGENTA}=== Verification ===${NC}"
echo -e "${CYAN}Docker containers:${NC}"
docker ps -a | grep -E 'k3d|gitlab|argocd' || echo "No related containers found."
echo -e "\n${CYAN}Docker volumes:${NC}"
docker volume ls | grep -E 'k3d|gitlab|argocd' || echo "No related volumes found."
echo -e "\n${CYAN}Docker networks:${NC}"
docker network ls | grep -E 'k3d|gitlab|argocd' || echo "No related networks found."

# Step 11: Add user to Docker group (if needed)
info "Adding user to Docker group to avoid permission issues..."
sudo usermod -aG docker $USER 2>/dev/null || warning "Failed to add user to Docker group."
success "User added to Docker group."

# Final message
success "Cleanup completed successfully! 🎉"
warning "Note: Some resources may require a system reboot to fully clean up."
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

# Step 1: Install ArgoCD
info "Starting ArgoCD installation: Creating namespaces and applying installation manifest..."
kubectl create namespace argocd
kubectl create namespace dev
success "Namespaces 'argocd' and 'dev' created successfully."

info "Applying ArgoCD installation manifest..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
success "ArgoCD installation manifest applied successfully."

info "Waiting for ArgoCD pods to be ready: This may take a few minutes..."
sleep 10
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
success "ArgoCD pods are ready."

# Step 2: Create ArgoCD Application
info "Creating ArgoCD application: Applying configuration from 'argocd.yaml'..."
kubectl apply -f ../confs/argocd.yaml -n argocd
success "ArgoCD application created successfully."

# Step 3: Set up port forwarding
info "Setting up port forwarding: Exposing ArgoCD and dev services..."
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server
kubectl port-forward svc/argocd-server -n argocd 8888:443 &
sleep 10
kubectl port-forward svc/svc-wil-playground -n dev 8880:8080 &
success "Port forwarding set up successfully."

# Step 4: Retrieve and display login credentials
info "Retrieving ArgoCD login credentials..."
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo -e "\n${MAGENTA}=== ArgoCD Access Information ===${NC}"
echo -e "${CYAN}ArgoCD UI: https://localhost:8888${NC}"
echo -e "${CYAN}Username: admin${NC}"
echo -e "${CYAN}Password: $PASSWORD${NC}"
success "Login credentials retrieved successfully."

# Step 5: Show ArgoCD pod status
info "Checking ArgoCD pod status..."
kubectl get pods -n argocd
success "ArgoCD setup completed successfully! 🎉"
warning "Note: If ArgoCD UI is not immediately accessible, please wait a few minutes for all services to initialize."
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
# Create k3d cluster
k3d cluster create cluster-hazaouya --api-port 6443 -p 8080:80@loadbalancer --agents 2 --wait
if [ $? -ne 0 ]; then
    echo_color $RED "Error creating k3d cluster!"
    exit 1
fi

# List clusters
k3d cluster list

# Get kubernetes nodes
kubectl get nodes

# Create namespaces
kubectl create namespace argocd
if [ $? -ne 0 ]; then
    echo_color $RED "Error creating namespace 'argocd'!"
    exit 1
fi

kubectl create namespace dev
if [ $? -ne 0 ]; then
    echo_color $RED "Error creating namespace 'dev'!"
    exit 1
fi

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
if [ $? -ne 0 ]; then
    echo_color $RED "Error installing ArgoCD!"
    exit 1
fi
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server
kubectl apply -f ./argocd_application.yaml -n argocd
kubectl port-forward svc/argocd-server -n argocd 8000:443 &

PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)

success "Setup completed!"
echo -e "\nArgoCD UI: https://localhost:8000"
echo "Username: admin"
echo "Password: $PASSWORD"

#kubectl port-forward svc/wil-playground-service -n dev 8001:8888

echo_color $GREEN "ArgoCD installed successfully and password updated!"

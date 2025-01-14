#!/bin/bash

# Script file for worker machine 
#sudo apt-get update -y
#sudo apt-get upgrade -y


apk add curl


# --token-file : Token file to use for authentication
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$1:6443 --token-file /vagrant/node-token --node-ip=$2" sh -s -

# make kubectl work out of the box
#echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

# Apply the configuration for the current session 
# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Verify K3s installation 
# kubectl get nodes


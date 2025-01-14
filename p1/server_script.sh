#!/bin/bash


apk add curl

 # 644 will allow it to be read by other unprivileged users on the host.
 
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --node-ip $1 --bind-address=$1" sh -s 

sleep 15

cp /var/lib/rancher/k3s/server/node-token /vagrant/.

# make kubectl work out of the box
#echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

# Apply the configuration for the current session 
#export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Verify K3s installation 
#kubectl get nodes
#!/bin/bash



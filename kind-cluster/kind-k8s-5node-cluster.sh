#!/bin/bash

if ! command -v kind > /dev/null 2>&1 ;then
sudo -v &> /dev/null && : || { echo "You must have sudo access to run this script - Or please run this via root" ; exit 1 ; }

sudo curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/
else
echo "Skipping kind tool is already install..!"
fi


cat << 'EOF' > kind-cluster-config
# Four node (3 workers) cluster config
kind: Cluster
name: k8scluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker
- role: worker
- role: worker
EOF

kind create cluster --config kind-cluster-config
[ $? -eq 0 ] && echo "Your cluster is ready can access k8s cluster using - kubectl get nodes"


#To delete cluster
#kind delete cluster --name k8scluster

#!/bin/bash

#https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#i-have-a-couple-of-nodes-with-low-utilization-but-they-are-not-scaled-down-why
export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')


# Prepare the manifest file with our cluster name and options
curl https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml | sed  "s/<YOUR CLUSTER NAME>/$CLUSTER_NAME\n            - --balance-similar-node-groups\n            - --skip-nodes-with-system-pods=false\n            - --scale-down-unneeded-time=5m/g" > autoscaler.yaml

# Create deployment
kubectl apply -f ./autoscaler.yaml

# Confirm deployment is done
kubectl get deploy -n kube-system -o wide

# Confirm autoscaler pod is running
kubectl get pods -n kube-system -l app=cluster-autoscaler

# View Cluster Autoscaler logs to see it's monitoring cluster load.
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler

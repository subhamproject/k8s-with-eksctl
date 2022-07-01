#!/bin/bash
#https://ngoyal16.medium.com/upgrade-eks-1-16-cluster-to-eks-1-17-using-eksctl-ef6f16b0af07
#https://www.eksworkshop.com/intermediate/320_eks_upgrades/upgrademng/

#To upgrade control Plane


eksctl upgrade cluster --name my-eks-cluster --approve

#edit the file and add additional nodegroup - DONT forget to change Version as AUTO - version: auto

#disable autoscaler 
kubectl scale deployments/cluster-autoscaler --replicas=0 -n kube-system

#create new node group

eksctl create nodegroup -f eks-managed.yaml


#Once new node group is create upgrade below To upgrade Pods

eksctl utils update-kube-proxy --cluster my-eks-cluster --approve

eksctl utils update-aws-node --cluster my-eks-cluster --approve

eksctl utils update-coredns --cluster my-eks-cluster --approve


# NOTE attach clusterr autosclaer policy to new node group
# NOTE - before deleting old node group dont forget to deattach cluster autoscaler policy else you wont be able to delete

# remove old node group

eksctl delete nodegroup -f eks-managed.yaml --only-missing --approve


#Once everything done - set cluster autoscaler deployment to 1

kubectl scale deployments/cluster-autoscaler --replicas=1 -n kube-system


#NOTE - if you have cluster autoscaler set it to 0 before you upgrade node group to avoid conflicts

kubectl scale deployments/cluster-autoscaler --replicas=0 -n kube-system


#To upgrade Node group

eksctl upgrade nodegroup --name my-mng  --cluster my-eks-cluster --kubernetes-version=1.22


#Once upgrade is done 

kubectl scale deployments/cluster-autoscaler --replicas=1 -n kube-system

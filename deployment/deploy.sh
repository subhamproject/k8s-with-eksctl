#!/bin/bash

kubectl apply -f nginx.yaml --record

kubectl rollout status deployment nginx

kubectl rollout pause deployment <deployment>

kubectl rollout resume deployment <deployment>

kubectl rollout history deployment nginx

kubectl rollout undo deployment <deployment>

kubectl rollout undo deployment nginx --to-revision=1


# To get Deployment Image

#to get current image from deployemnt
k get deploy/blue-target -o jsonpath="{..image}"|head -n 1

sh "sed -i 's/hellonodejs:latest/hellonodejs:eks/g' deploy.yaml"
sh 'kubectl apply -f deploy.yaml'
sh 'kubectl rollout restart deployment hello-world-nodejs'

cat blue-deployment.yaml |sed 's#707015264015.dkr.ecr.us-west-2.amazonaws.com/blue:blue-v3#707015264015.dkr.ecr.us-west-2.amazonaws.com/blue:blue-v1#'

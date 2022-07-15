#!/bin/bash

# export the first node name as a variable
export FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[2].metadata.name')

kubectl label nodes ${FIRST_NODE_NAME} azname=az1

kubectl label nodes ${FIRST_NODE_NAME} azname- --> to remove lables

kubectl get nodes --show-labels


use In, NotIn, Exists and DoesNotExist.


kubectl label nodes prod-worker app=store
kubectl label nodes prod-worker app=web-store
kubectl label nodes prod-worker2 app=web-store
kubectl label nodes prod-worker2  app=store
kubectl label nodes prod-worker3 app=store
kubectl label nodes prod-worker3 app=web-store

#!/bin/bash

kubectl get events --field-selector type=Warning

kubectl get events --field-selector involvedObject.kind!=Pod

kubectl get events --field-selector involvedObject.kind=Node,involvedObject.name=minikube

kubectl get events -w

kubectl get events –field-selector type!=Normal

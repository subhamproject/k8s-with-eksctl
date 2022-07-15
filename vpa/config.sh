#!/bin/bash

#Metric server version v0.6.1 works for k8s 1.24 - pls refer support version before deploy

wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

cat components.yaml |sed "s|- --metric-resolution=15s|- --metric-resolution=15s\n        - --kubelet-insecure-tls|g" > metrics.yaml

kubectl apply -f metrics.yaml

(git clone https://github.com/kubernetes/autoscaler.git ;cd autoscaler/vertical-pod-autoscaler/ ; ./hack/vpa-up.sh)

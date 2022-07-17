#!/bin/bash

kubectl delete -f deployment.yaml
kubectl delete -f vpa.yal
kubectl delete -f service.yaml
kubectl delete -f metrics.yaml

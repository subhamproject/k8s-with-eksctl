#!/bin/bash

kubectl delete -f deployment.yaml
kubectl delte -f vpa.yal
kubectl delte -f service.yaml
kubectl delete -f metrics.yaml

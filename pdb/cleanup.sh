#!/bin/bash

kubectl delete -f pdb.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

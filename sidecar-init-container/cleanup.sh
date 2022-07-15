#!/bin/bash

kubectl delete -f init.yaml
kubectl delete -f  sidecar-es-with-ssl.yaml
kubectl delete -f  sidecar-es.yaml

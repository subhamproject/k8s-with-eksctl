#!/bin/bash

kubectl create configmap app-settings --from-file=app-container/settings/app.properties 

kubectl create configmap app-settings --from-file=app-container/settings/app.properties--from-file=app-container/settings/backend.properties 

kubectl create configmap app-env-file--from-env-file=app-container/settings/app-env-file.properties

kubectl create configmap app-settings --from-file=app-container/settings/


kubectl get configmaps <name> -o yaml


kubectl describe configmaps <name>

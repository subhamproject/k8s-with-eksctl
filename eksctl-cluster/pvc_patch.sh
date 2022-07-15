#!/bin/bash

k get sc

k get sc gp2 -o yaml

kubectl patch sc gp2 -p '{"allowVolumeExpansion": true}'


k get pv

kubectl get pvc pet2cattle-data -o yaml | sed 's/storage: 35Gi/storage: 40Gi/g' | kubectl apply -f -

k get pv

k get pvc

kubectl exec -it pet2cattle-79979695b-7rmg6 -- df -hP

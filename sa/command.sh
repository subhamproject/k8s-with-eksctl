#!/bin/bash

# https://jwt.io/

kubectl exec -it <pod> -- sh

apk add curl

TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token

curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods/ --insecure

curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods/ --insecure

kubectl get pods -A

kubectl exec -n <namespace> <pod-name>-- env | grep AWS

curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/kube-system/pods/coredns-d798c9dd-pdswq/log --insecure

kubectl describe clusterrole system:discovery


AWS_ROLE_ARN=arn:aws:iam::707015264015:role/eksctl-demo-eks-cluster-addon-iamserviceacco-Role1-16PMTN0AX6R54
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2

#!/bin/bash

eksctl utils associate-iam-oidc-provider  --cluster=demo-eks-cluster --approve

POLICY_ARN=$(aws --query Policy.Arn --output text iam create-policy --policy-name nginx-parameter-deployment-policy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["ssm:GetParameter", "ssm:GetParameters"],
        "Resource": ["arn:aws:ssm:us-west-2:707015264015:parameter/Prod/*"]
    } ]
}')

eksctl create iamserviceaccount --name nginx-sa  --cluster demo-eks-cluster --attach-policy-arn "$POLICY_ARN" --approve --override-existing-serviceaccounts



helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm install -n kube-system csi-secrets-store \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  secrets-store-csi-driver/secrets-store-csi-driver

kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

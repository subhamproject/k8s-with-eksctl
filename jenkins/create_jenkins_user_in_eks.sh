#!/bin/bash

#https://eksctl.io/usage/iam-identity-mappings/

CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')

eksctl create iamidentitymapping \
    --cluster $CLUSTER_NAME \
    --region=us-west-2 \
    --arn arn:aws:iam::707015264015:role/full-eks-access-role \
    --username jenkins \
    --group system:masters \
    --no-duplicate-arns

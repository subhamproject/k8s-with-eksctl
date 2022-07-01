#!/bin/bash


CLUSTER_NAME=my-eks-cluster
NG_NAME=my-mng-new
NG_STACK_NAME=eksctl-$CLUSTER_NAME-nodegroup-$NG_NAME

export AWS_DEFAULT_REGION=us-east-1


ROLE=$(aws cloudformation list-stack-resources  --stack-name $NG_STACK_NAME | jq -r '.[] | .[] | select(.LogicalResourceId == "NodeInstanceRole").PhysicalResourceId')
POLICY_ARN=$(aws iam list-policies --max-items 20|grep AmazonEKSClusterAutoscalerPolicy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g')


aws iam detach-role-policy \
--role-name $ROLE \
--policy-arn $POLICY_ARN

# Delete cluster
#eksctl delete cluster --name=$CLUSTER_NAME

#!/bin/bash

CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')


NG_NAME=ng-new
NG_STACK_NAME=eksctl-$CLUSTER_NAME-nodegroup-$NG_NAME


ROLE=$(aws cloudformation list-stack-resources  --stack-name $NG_STACK_NAME | jq -r '.[] | .[] | select(.LogicalResourceId == "NodeInstanceRole").PhysicalResourceId')

# Confirm role
echo $ROLE

if [[ $(aws iam list-policies --max-items 20|grep AmazonEKSClusterAutoscalerPolicy|wc -l) -ge 1 ]];then
POLICY_ARN=$(aws iam list-policies --max-items 20|grep AmazonEKSClusterAutoscalerPolicy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g')
# Create the policy
else
POLICY_ARN=$(aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document \
'{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}' | jq -r '.[].Arn')
fi
# Confirm policy arn
echo $POLICY_ARN

# Attach policy to the role
aws iam attach-role-policy \
--role-name $ROLE \
--policy-arn $POLICY_ARN

# Confirm role policies
aws iam list-attached-role-policies --role-name $ROLE

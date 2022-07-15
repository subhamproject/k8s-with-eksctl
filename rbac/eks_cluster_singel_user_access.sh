#!/bin/bash


USER_NAME="eks-ro"

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')

if [[ $(aws iam list-policies --max-items 30|grep eks-readonly-policy|wc -l) -ge 1 ]];then
POLICY_ARN=$(aws iam list-policies --max-items 30|grep eks-readonly-policy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g')
else
# Create the policy
POLICY_ARN=$(aws iam create-policy --policy-name=eks-readonly-policy --policy-document='{"Version": "2012-10-17", "Statement": {"Sid": "EKSReadOnly", "Effect": "Allow", "Action": ["eks:DescribeCluster", "eks:ListCluster" ], "Resource": "*" }}'|jq -r '.[].Arn')
fi

# Confirm policy arn
echo $POLICY_ARN
#Create IAM user
if ! aws iam get-user --user-name $USER_NAME  > /dev/null 2>&1 ;then
aws iam create-user --user-name=$USER_NAME
fi

[ $? -eq 0 ] && USER_ARN=$(aws iam get-user --user-name $USER_NAME|jq -r '.[].Arn')

aws iam attach-user-policy --user-name=$USER_NAME --policy-arn=$POLICY_ARN

eksctl create iamidentitymapping \
  --cluster $CLUSTER_NAME \
  --arn $USER_ARN \
  --username $USER_NAME

if [ $(aws iam list-access-keys --user-name $USER_NAME --query 'AccessKeyMetadata[*].AccessKeyId' --output text|wc -l) -lt 1 ] ;then
aws iam create-access-key --user-name $USER_NAME | tee /tmp/${USER_NAME}.json
fi

sleep 3


cat << EOF | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: eks-readonly-user-test
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: eks-readonly-user-role-binding
subjects:
- kind: User
  name: eks-ro
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: eks-readonly-user-test
  apiGroup: rbac.authorization.k8s.io
EOF


grep '$USER_NAME' ~/.aws/config > /dev/null 2>&1 || aws configure  --profile $USER_NAME set aws_access_key_id $(jq -r .AccessKey.AccessKeyId /tmp/${USER_NAME}.json) && \
                                            aws configure  --profile $USER_NAME set aws_secret_access_key $(jq -r .AccessKey.SecretAccessKey /tmp/${USER_NAME}.json) && \
                                            aws configure  --profile $USER_NAME set region us-west-2
export AWS_PROFILE=$USER_NAME
export KUBECONFIG=/tmp/kubeconfig-dev && aws eks --profile $USER_NAME update-kubeconfig --name $CLUSTER_NAME

#aws eks update-kubeconfig --name $CLUSTER_NAME --region us-west-2 --role-arn arn:aws:iam::${ACCOUNT_ID}:role/k8sDemo
rm -rf /tmp/${USER_NAME}-ro.json
#export KUBECONFIG=/tmp/kubeconfig-dev && aws eks update-kubeconfig --name demo-eks-cluster --region us-west-2 --role-arn arn:aws:iam::${ACCOUNT_ID}:role/k8s-New

#!/bin/bash


IAM_USER="New"
IAM_GROUP="k8sNew"
ROLE_NAME="k8s-New"

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')

if [[ $(aws iam list-policies --max-items 30|grep eks-readonly-policy|wc -l) -ge 1 ]];then
POLICY_ARN=$(aws iam list-policies --max-items 30|grep eks-readonly-policy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g')
else
POLICY_ARN=$(aws iam create-policy --policy-name=eks-readonly-policy --policy-document='{"Version": "2012-10-17", "Statement": {"Sid": "EKSReadOnly", "Effect": "Allow", "Action": ["eks:DescribeCluster", "eks:ListCluster" ], "Resource": "*" }}'|jq -r '.[].Arn')
fi
# Confirm policy arn
echo $POLICY_ARN


export POLICY=$(echo -n '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'; echo -n "$ACCOUNT_ID"; echo -n ':root"},"Action":"sts:AssumeRole","Condition":{}}]}')

echo ACCOUNT_ID=$ACCOUNT_ID
echo POLICY=$POLICY

ROLE_ARN=$(aws iam create-role \
  --role-name $ROLE_NAME \
  --description "Kubernetes role for complete access to cluster." \
  --assume-role-policy-document "$POLICY" \
  --output text \
  --query 'Role.Arn')

echo $ROLE_ARN

if ! aws iam get-group --group-name $IAM_GROUP > /dev/null 2>&1 ;then
aws iam create-group --group-name $IAM_GROUP
fi

DEV_GROUP_POLICY=$(echo -n '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeOrganizationAccountRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::'; echo -n "$ACCOUNT_ID"; echo -n :role/$ROLE_NAME'"
    }
  ]
}')
echo DEV_GROUP_POLICY=$DEV_GROUP_POLICY

aws iam put-group-policy \
--group-name $IAM_GROUP \
--policy-name ${ROLE_NAME}-policy \
--policy-document "$DEV_GROUP_POLICY"

aws iam attach-group-policy --policy-arn $POLICY_ARN --group-name $IAM_GROUP

#Create IAM user
if ! aws iam get-user --user-name $IAM_USER  > /dev/null 2>&1 ;then
aws iam create-user --user-name=$IAM_USER
fi

if ! aws iam list-groups-for-user --user-name $IAM_USER > /dev/null 2>&1 ;then
aws iam add-user-to-group --group-name $IAM_GROUP --user-name $IAM_USER
fi


if [ $(aws iam list-access-keys --user-name $IAM_USER --query 'AccessKeyMetadata[*].AccessKeyId' --output text|wc -l) -lt 1 ] ;then
aws iam create-access-key --user-name $IAM_USER | tee /tmp/${IAM_USER}.json
fi

sleep 3

cat << EOF | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: eks-admin-role-new
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
  name: eks-admin-role-new
subjects:
- kind: Group
  name: devops
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: eks-admin-role-new
  apiGroup: rbac.authorization.k8s.io
EOF

sleep 2

eksctl create iamidentitymapping \
  --cluster $CLUSTER_NAME  \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --username $IAM_USER \
  --group devops


grep '${IAM_USER}' ~/.aws/config >/dev/null 2>&1 || aws configure --profile ${IAM_USER}-user set aws_access_key_id $(jq -r .AccessKey.AccessKeyId /tmp/${IAM_USER}.json)&& \
                                            aws configure --profile ${IAM_USER}-user set aws_secret_access_key $(jq -r .AccessKey.SecretAccessKey /tmp/${IAM_USER}.json)&& \
                                            aws configure --profile ${IAM_USER} set region us-west-2 && \
                                            aws configure --profile ${IAM_USER} set role_arn $ROLE_ARN && \
                                            aws configure --profile ${IAM_USER} set source_profile ${IAM_USER}-user

[ $? -eq 0 ] && rm -rf /tmp/${IAM_USER}.json

export KUBECONFIG=/tmp/kubeconfig-dev && aws eks update-kubeconfig --name $CLUSTER_NAME --region us-west-2 --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}
#export KUBECONFIG=/tmp/kubeconfig-dev && aws eks update-kubeconfig --name demo-eks-cluster --region us-west-2 --role-arn arn:aws:iam::${ACCOUNT_ID}:role/k8s-New

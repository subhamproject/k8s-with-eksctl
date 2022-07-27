#!/bin/bash

export EBS_CSI_POLICY_NAME="Amazon_EBS_CSI_Driver"
export ACCOUNT_ID=$(aws sts get-caller-identity|jq -r '.Account')
export AWS_REGION=$(aws configure get region)
export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')


# download the IAM policy document
curl -sSL -o ebs-csi-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json

# Create the IAM policy
if [[ $(aws iam list-policies --max-items 30|grep Amazon_EBS_CSI_Driver|wc -l) -eq 0 ]];then
aws iam create-policy \
  --region ${AWS_REGION} \
  --policy-name ${EBS_CSI_POLICY_NAME} \
  --policy-document file://ebs-csi-policy.json
fi

# export the policy ARN as a variable
export EBS_CSI_POLICY_ARN=$(aws --region ${AWS_REGION} iam list-policies --query 'Policies[?PolicyName==`'$EBS_CSI_POLICY_NAME'`].Arn' --output text)

# Create an IAM OIDC provider for your cluster
eksctl utils associate-iam-oidc-provider \
  --region=$AWS_REGION \
  --cluster=$CLUSTER_NAME \
  --approve

# Create a service account
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --name ebs-csi-controller-irsa \
  --namespace kube-system \
  --attach-policy-arn $EBS_CSI_POLICY_ARN \
  --override-existing-serviceaccounts \
  --approve

# add the aws-ebs-csi-driver as a helm repo
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver

# search for the driver
helm search  repo aws-ebs-csi-driver


helm upgrade --install aws-ebs-csi-driver \
  --version=2.8.0 \
  --namespace kube-system \
  --set serviceAccount.controller.create=false \
  --set serviceAccount.snapshot.create=false \
  --set enableVolumeScheduling=true \
  --set enableVolumeResizing=true \
  --set enableVolumeSnapshot=true \
  --set serviceAccount.snapshot.name=ebs-csi-controller-irsa \
  --set serviceAccount.controller.name=ebs-csi-controller-irsa \
  aws-ebs-csi-driver/aws-ebs-csi-driver

kubectl -n kube-system rollout status deployment ebs-csi-controller


cat << EoF > mysql-storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: mysql-gp2
provisioner: ebs.csi.aws.com # Amazon EBS CSI driver
parameters:
  type: gp2
  encrypted: 'true' # EBS volumes will always be encrypted by default
volumeBindingMode: WaitForFirstConsumer # EBS volumes are AZ specific
reclaimPolicy: Delete
mountOptions:
- debug
EoF

kubectl create -f mysql-storageclass.yaml

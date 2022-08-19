#!/bin/bash

export AWS_REGION=$(aws configure get region)

CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')
NG_NAME=${CLUSTER_NAME}-ng-new
NG_STACK_NAME=eksctl-$CLUSTER_NAME-nodegroup-$NG_NAME

[ ! -f iam_policy.json ] && curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy_v1_to_v2_additional.json

if [[ $(aws iam list-policies --max-items 20|grep AWSLoadBalancerControllerIAMPolicy|wc -l) -ge 1 ]];then
echo "Policy exists..skipping"
POLICY_ARN=$(aws iam list-policies --max-items 20|grep AWSLoadBalancerControllerIAMPolicy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g')
echo $POLICY_ARN
else
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
[ $? -eq 0 ] && POLICY_ARN=$(aws iam list-policies --max-items 20|grep AWSLoadBalancerControllerIAMPolicy|grep Arn|cut -d':' -f2-|sed 's|"||g;s|,||g;s| ||g') && echo $POLICY_ARN
fi


eksctl create iamserviceaccount --cluster $CLUSTER_NAME --namespace kube-system --name aws-load-balancer-controller --attach-policy-arn $POLICY_ARN --override-existing-serviceaccounts --approve

kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master
kubectl get crd

helm repo add eks https://aws.github.io/eks-charts

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller -n kube-system

kubectl -n kube-system rollout status deployment aws-load-balancer-controller

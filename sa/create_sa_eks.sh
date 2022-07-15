#!/bin/bash


export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')


S3_RO_POLICY=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonS3ReadOnlyAccess`].Arn'|grep arn |sed 's|"||g;s|,||g;s| ||g')

S3_FULL_POLICY=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonS3FullAccess`].Arn'|grep arn |sed 's|"||g;s|,||g;s| ||g')

ADMIN_POLICY=$(aws iam list-policies --query 'Policies[?PolicyName==`AdministratorAccess`].Arn'|grep arn |sed 's|"||g;s|,||g;s| ||g')

eksctl create iamserviceaccount \
    --name s3-readonly \
    --namespace default \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $S3_RO_POLICY \
    --approve \
    --override-existing-serviceaccounts

eksctl create iamserviceaccount \
    --name s3-fullacess \
    --namespace default \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $S3_FULL_POLICY \
    --approve \
    --override-existing-serviceaccounts

eksctl create iamserviceaccount \
    --name admin \
    --namespace default \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $ADMIN_POLICY \
    --approve \
    --override-existing-serviceaccounts

#kubectl get sa iam-test


#kubectl describe sa iam-test

cat <<EoF> job-s3-ro.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: eks-iam-test-s3-ro
spec:
  template:
    metadata:
      labels:
        app: eks-iam-test-s3-ro
    spec:
      serviceAccountName: s3-readonly
      containers:
      - name: eks-iam-test-ro
        image: amazon/aws-cli:latest
        args: ["s3", "ls"]
      restartPolicy: Never
EoF

#kubectl apply -f job-s3.yaml

#kubectl logs -l app=eks-iam-test-s3


cat <<EoF> job-s3-full.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: eks-iam-test-s3-full
spec:
  template:
    metadata:
      labels:
        app: eks-iam-test-s3-full
    spec:
      serviceAccountName: s3-fullacess
      containers:
      - name: eks-iam-test-full
        image: amazon/aws-cli:latest
        args: ["aws", "s3api", "create-bucket", "--bucket", "eks-iam-test-s3-full-testing", "--region", "${AWS_REGION}"]
      restartPolicy: Never
  backoffLimit: 0
EoF



cat <<EoF> job-admin.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: eks-iam-test-admin-access
spec:
  template:
    metadata:
      labels:
        app: eks-iam-test-admin-acess
    spec:
      serviceAccountName: admin
      containers:
      - name: eks-iam-test-admin-access
        image: amazon/aws-cli:latest
        args: ["aws", "--region", "${AWS_REGION}", "ec2", "run-instances", "--image-id", "ami-098e42ae54c764c35", "--instance-type", "t2.micro"]
      restartPolicy: Never
  backoffLimit: 0
EoF

#kubectl apply -f job-ec2.yaml

#kubectl logs -l app=eks-iam-test-ec2

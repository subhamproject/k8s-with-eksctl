#!/bin/bash


export AWS_REGION=$(aws configure get region)

VERSION="6.3" #6.8

MY_IP=$(curl -qs https://checkip.amazonaws.com)

DOMAIN_NAME="k8s-log"
ACCOUNT_ID=$(aws sts get-caller-identity|jq -r '.Account')
REGION=$(aws configure get region)

aws --region $REGION es create-elasticsearch-domain   --domain-name $DOMAIN_NAME --elasticsearch-version $VERSION --elasticsearch-cluster-config   InstanceType=t3.small.elasticsearch,InstanceCount=1   --ebs-options EBSEnabled=true,VolumeType=gp2,VolumeSize=10


[ $? -eq 0 ] && sleep 30

aws es update-elasticsearch-domain-config --domain-name $DOMAIN_NAME --access-policies '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::'${ACCOUNT_ID}':root"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:'${REGION}':'${ACCOUNT_ID}':domain/'${DOMAIN_NAME}'/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:'${REGION}':'${ACCOUNT_ID}':domain/'${DOMAIN_NAME}'/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "'${MY_IP}'/32"
        }
      }
    }
  ]
}'

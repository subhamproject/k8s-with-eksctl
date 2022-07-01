#!/usr/bin/env bash

[ $(sudo rpm -qa|grep jq|wc -l) -eq 0 ] && sudo yum install jq -y

TAG=$TAG
REGION=$AWS_REGION
REPO=$ECR_REPO
grep 'region' ~/.aws/config > /dev/null 2>&1 || aws configure set default.region $REGION

REGISTRY="$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"
docker build -t $REGISTRY/$REPO:$TAG  --build-arg MESSAGE="$MESSAGE" -f $(dirname $0)/Dockerfile .

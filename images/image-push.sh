#!/usr/bin/env bash

TAG=$TAG

REGION=$AWS_REGION
REPO=$ECR_REPO
grep 'region' ~/.aws/config > /dev/null 2>&1 || aws configure set default.region $REGION

REGISTRY="$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login -u AWS --password-stdin "https://$REGISTRY"
[ $? -eq 0 ] && docker push $REGISTRY/$REPO:$TAG

#!/bin/bash

MY_IP=$(curl -qs https://checkip.amazonaws.com)

DOMAIN_NAME="k8s-logs"
ACCOUNT_ID=$(aws sts get-caller-identity|jq -r '.Account')
REGION=$(aws configure get region)


aws es delete-elasticsearch-domain --domain-name $DOMAIN_NAME


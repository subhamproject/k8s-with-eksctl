#!/bin/bash

export AWS_REGION=$(aws configure get region)

ES_DOMAIN_NAME=$(aws es list-domain-names --region $AWS_REGION|jq '.DomainNames[].DomainName'|sed 's|"||g')

if [[ $(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint") == "None" ]];then
echo "Please wait for ELK cluster to be up - it may take a while - Please check in AWS console and try again after sometime" ; exit 1
fi

MY_IP=$(curl -qs https://checkip.amazonaws.com)
ACCOUNT_ID=$(aws sts get-caller-identity|jq -r '.Account')
export AWS_REGION=$(aws configure get region)
export CLUSTER_NAME=$(eksctl get cluster|sed '1d'|awk '{print $1}')


#https://faun.pub/configure-aws-elasticsearch-service-with-eks-cluster-7cff1689e515

cat <<EoF > fluent-bit-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:*"
            ],
            "Resource": "arn:aws:es:${AWS_REGION}:${ACCOUNT_ID}:domain/${ES_DOMAIN_NAME}/*",
            "Effect": "Allow"
        }
    ]
}
EoF


if [[ $(aws iam list-policies --max-items 30|grep fluent-bit-policy|wc -l) -eq 0 ]];then
aws iam create-policy   \
  --policy-name fluent-bit-policy \
  --policy-document file://fluent-bit-policy.json
fi


kubectl create namespace logging

eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/fluent-bit-policy" \
    --approve \
    --override-existing-serviceaccounts



kubectl -n logging describe sa fluent-bit


# We need to retrieve the Fluent Bit Role ARN
export FLUENTBIT_ROLE=$(eksctl get iamserviceaccount --cluster $CLUSTER_NAME --namespace logging -o json | jq '.[].status.roleARN' -r)

# get the Amazon OpenSearch Endpoint
export ES_ENDPOINT=$(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint")

curl -Ss https://www.eksworkshop.com/intermediate/230_logging/deploy.files/fluentbit.yaml \
    | envsubst > fluentbit.yaml


kubectl apply -f fluentbit.yaml

kubectl --namespace=logging get pods

echo "OpenSearch Dashboards URL: https://${ES_ENDPOINT}/_dashboards/"

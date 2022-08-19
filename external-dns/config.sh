#!/bin/bash

export AWS_REGION=$(aws configure get region)


#route53 policy
cat << EOF > route_53_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

export AWS_DEFAULT_REGION=us-west-2

REGION=$(aws configure get region)
DOMAIN="devopsforall.tk"

CLUSTER=$(aws eks list-clusters --region $REGION --query clusters[0] --output text)

if [[ $(aws route53 list-hosted-zones-by-name |grep $DOMAIN|wc -l) -lt 1 ]];then
aws route53 create-hosted-zone --name $DOMAIN --caller-reference "My-Domain-testing-$(date +%s)" --hosted-zone-config Comment="My Domain Testing"
fi

sleep 5

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $DOMAIN|jq -r '.HostedZones[].Id'|cut -d'/' -f3)

LIST_RECORD_SET=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID)

if [[ $(aws iam list-policies --max-items 30|grep AllowExternalDNSUpdates|wc -l) -lt 1 ]];then
aws iam create-policy --policy-name "AllowExternalDNSUpdates" --policy-document file://route_53_policy.json
fi

export POLICY_ARN=$(aws iam list-policies \
 --query 'Policies[?PolicyName==`AllowExternalDNSUpdates`].Arn' --output text)

eksctl --region $REGION create iamserviceaccount \
 --name external-dns \
 --namespace kube-system \
 --cluster $CLUSTER \
 --attach-policy-arn $POLICY_ARN \
 --approve --override-existing-serviceaccounts


kubectl describe sa external-dns -n kube-system

cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods","nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  labels:
    app.kubernetes.io/name: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns
    namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
  labels:
    app.kubernetes.io/name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: external-dns
  template:
    metadata:
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
        - name: external-dns
          image: k8s.gcr.io/external-dns/external-dns:v0.11.0
          args:
            - --source=service
            - --source=ingress
            - --domain-filter=$DOMAIN
            - --provider=aws
            - --policy=sync  #sync, create-only ,upsert-only
            - --aws-zone-type=public 
            - --registry=txt
            - --txt-owner-id=$HOSTED_ZONE_ID
          env:
            - name: AWS_DEFAULT_REGION
              value: $REGION
EOF

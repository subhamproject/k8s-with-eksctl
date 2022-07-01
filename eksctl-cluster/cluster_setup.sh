#!/bin/bash

export USERID=$(id -u)
export PATH="$PATH:/usr/local/bin"
export GROUPID=$(id -g)
cd $(dirname $0)

docker-compose -f compose.yaml \
    run --rm -w "$WORKSPACE" \
    --name eks-${BUILD_NUMBER} eksctl create cluster -f eksctl-cluster/eks-cluster.yaml

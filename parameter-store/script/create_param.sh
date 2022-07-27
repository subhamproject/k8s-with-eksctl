#!/bin/bash
## Create two new parameters of type string

aws ssm put-parameter \
    --name "/Prod/Username" \
    --type "SecureString" \
    --value "admin" \
    --overwrite


aws ssm put-parameter \
    --name "/Prod/Password" \
    --type "SecureString" \
    --value "pa\$\$word" \
    --overwrite


aws ssm put-parameter \
    --region ap-southeast-1 \
    --name MY_GITHUB_PRIVATE_KEY \
    --type SecureString \
    --key-id alias/aws/ssm \
    --value file://my_github_private.key



#--value "$(cat my_github_private.key)"

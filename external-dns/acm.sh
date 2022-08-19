#!/usr/bin/env bash
#https://gist.github.com/michimani/ed5f45975f8758bdab818507a51e7b5f

export AWS_DEFAULT_REGION=us-west-2

DOMAIN=${1:-demo.devopsforall.tk}

################################################################################
# Requests a certificate based on the provided domain name from ACM.
################################################################################
ACM_CERTIFICATE_ARN=$(aws acm request-certificate \
--domain-name "$DOMAIN" \
--subject-alternative-names "*.$DOMAIN" \
--validation-method DNS \
--query CertificateArn \
--output text)
 
echo "[ACM]          Certificate ARN: $ACM_CERTIFICATE_ARN"
 
################################################################################
# The following commands extract the name and value of the required CNAME record
# that needs to be created to confirm ownership of the domain the certificate
# will be associated with.
################################################################################

VALIDATION_NAME="$(aws acm describe-certificate \
--certificate-arn "$ACM_CERTIFICATE_ARN" \
--query "Certificate.DomainValidationOptions[?DomainName=='$DOMAIN'].ResourceRecord.Name" \
--output text)"
 
VALIDATION_VALUE="$(aws acm describe-certificate \
--certificate-arn "$ACM_CERTIFICATE_ARN" \
--query "Certificate.DomainValidationOptions[?DomainName=='$DOMAIN'].ResourceRecord.Value" \
--output text)"
 
echo "[ACM]          Certificate validation record: $VALIDATION_NAME CNAME $VALIDATION_VALUE"
 
################################################################################
# Request the hosted zone from Route 53 that is associated with the domain that
# the validation CNAME record will be associated with.
################################################################################

R53_HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
--dns-name "$DOMAIN" \
--query "HostedZones[?Name=='$DOMAIN.'].Id" \
--output text)"
 
R53_HOSTED_ZONE=${R53_HOSTED_ZONE_ID##*/}
 
echo "[Route 53]     Hosted Zone ID: $R53_HOSTED_ZONE"
 
################################################################################
# Create the change batch needed to upset the validation record, then run the
# command to apply the change batch.
################################################################################

R53_CHANGE_BATCH=$(cat <<EOM
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$VALIDATION_NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$VALIDATION_VALUE"
          }
        ]
      }
    }
  ]
}
EOM
)
 
R53_CHANGE_BATCH_REQUEST_ID="$(aws route53 change-resource-record-sets \
--hosted-zone-id "$R53_HOSTED_ZONE" \
--change-batch "$R53_CHANGE_BATCH" \
--query "ChangeInfo.Id" \
--output text)"
 
################################################################################
# Wait 1) for the validation record to be created, and 2) for the certificate
# to validate the domain and issue the certificate.
################################################################################
echo "[Route 53]     Waiting for validation records to be created..."
aws route53 wait resource-record-sets-changed --id "$R53_CHANGE_BATCH_REQUEST_ID"
 
echo "[ACM]          Waiting for certificate to validate..."
aws acm wait certificate-validated --certificate-arn "$ACM_CERTIFICATE_ARN"
 
ACM_CERTIFICATE_STATUS="$(aws acm describe-certificate \
--certificate-arn "$ACM_CERTIFICATE_ARN"
--query "Certificate.Status"
--output text)"
 
ACM_CERTIFICATE="$(aws acm describe-certificate \
--certificate-arn "$ACM_CERTIFICATE_ARN"
--output json)"
 
################################################################################
# Output the certificate description from ACM, and highlight the status of the
# certificate.
################################################################################
if [ "$ACM_CERTIFICATE_STATUS" = "ISSUED" ]; then
  GREP_GREEN="1;32"
  echo "$ACM_CERTIFICATE" | GREP_COLOR="$GREP_GREEN" grep --color -E "\"Status\": \"${ACM_CERTIFICATE_STATUS}\"|$"
else
  GREP_RED="1;31"
  echo "$ACM_CERTIFICATE" | GREP_COLOR="$GREP_RED" grep --color -E "\"Status\": \"${ACM_CERTIFICATE_STATUS}\"|$"
fi

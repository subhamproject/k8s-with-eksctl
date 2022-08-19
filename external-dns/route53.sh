#!/bin/bash

export AWS_REGION=$(aws configure get region)


set -e

if [ $# != 3 ] || [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
	echo -e "Three parameters are required
  1st - string: Hosted Domain Name on Route 53 (e.g. example.com)
  2nd - string: Domain Name for Certificate (e.g. sub.mexample.com)
  3rd - string: Target Region  (e.g. us-east-1)
  example command
  \t sh ./issue-acm-certificate.sh example.com sub.example.com"
	exit
fi

export AWS_REGION=$(aws configure get region)

HOSTED_DOMAIN=$1
TARGET_DOMAIN=$2
REGION=$3
NONE="None"

request_certificate() {
	# request certificate
	echo "Request certificate for '${TARGET_DOMAIN}' to ACM."
	CERT_ARN=$(
		aws acm request-certificate \
			--domain-name "${TARGET_DOMAIN}" \
			--subject-alternative-names "*.${TARGET_DOMAIN}" \
			--validation-method DNS \
			--region "${REGION}" \
			--output text
	) &&
		sleep 5 &&
		echo -e "\t CERT_ARN = ${CERT_ARN}"
}

if ! request_certificate; then
	echo "Failed to request certificate."
	exit 1
fi

get_recordset_info() {
	# Get record set for domain validation
	echo "Get record set to validate domain in Route 53."
	VALIDATION_RECORD_NAME=$(
		aws acm describe-certificate \
			--certificate-arn "${CERT_ARN}" \
			--query "Certificate.DomainValidationOptions[0].ResourceRecord.Name" \
			--region "${REGION}" \
			--output text
	) &&
		echo -e "\t VALIDATION_RECORD_NAME = ${VALIDATION_RECORD_NAME}"

	VALIDATION_RECORD_VALUE=$(
		aws acm describe-certificate \
			--certificate-arn "${CERT_ARN}" \
			--query "Certificate.DomainValidationOptions[0].ResourceRecord.Value" \
			--region "${REGION}" \
			--output text
	) &&
		echo -e "\t VALIDATION_RECORD_VALUE = ${VALIDATION_RECORD_VALUE}"

	HOSTED_ZONE_ID=$(
		aws route53 list-hosted-zones \
			--query "HostedZones[?Name=='${HOSTED_DOMAIN}.'].Id" \
			--output text
	) &&
		echo -e "\t HOSTED_ZONE_ID = ${HOSTED_ZONE_ID}"

	if [ "$VALIDATION_RECORD_NAME" == $NONE ] || [ "$VALIDATION_RECORD_VALUE" == $NONE ] || [ "$HOSTED_DOMAIN" == $NONE ]; then
		exit 1
	fi
}

if ! get_recordset_info; then
	echo "Failed to get the parameters required for domain validation."
	exit 1
fi

change_record_set() {
	# Change resource record set for domain validation at Route 53
	echo "Change resource record set for domain validation at Route 53."
	CHANGE_ID=$(
		aws route53 change-resource-record-sets \
			--hosted-zone-id "${HOSTED_ZONE_ID}" \
			--change-batch \
			"{
      \"Changes\": [
        {
          \"Action\": \"CREATE\",
          \"ResourceRecordSet\": {
            \"Name\": \"${VALIDATION_RECORD_NAME}\",
            \"Type\": \"CNAME\",
            \"TTL\": 300,
            \"ResourceRecords\": [{\"Value\": \"${VALIDATION_RECORD_VALUE}\"}]
          }
        }
      ]
    }" \
			--query "ChangeInfo.Id" \
			--output text
	) &&
		echo -e "\t Change ID : ${CHANGE_ID}\n"
}

if ! change_record_set; then
	echo "Failed to change resource record set for domain validation."
	exit 1
fi

echo -e "\nFinished to request certificate and create record set to validate domain.
Please run command bellow to check validation status.

aws acm describe-certificate \\
  --certificate-arn ${CERT_ARN} \\
  --query \"Certificate.DomainValidationOptions[0].ValidationStatus\" \\
  --region ${REGION} \\
  --output text"

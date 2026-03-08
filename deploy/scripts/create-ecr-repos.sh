#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <aws-region> <aws-account-id>"
  exit 1
fi

AWS_REGION="$1"
AWS_ACCOUNT_ID="$2"
ECR_REPOSITORY="streamingapp-brm"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

if aws ecr describe-repositories --region "${AWS_REGION}" --repository-names "${ECR_REPOSITORY}" >/dev/null 2>&1; then
  echo "ECR repository exists: ${ECR_REPOSITORY}"
else
  aws ecr create-repository --region "${AWS_REGION}" --repository-name "${ECR_REPOSITORY}" >/dev/null
  echo "Created ECR repository: ${ECR_REPOSITORY}"
fi

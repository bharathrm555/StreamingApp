#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <aws-region> <aws-account-id> <k8s-namespace> <secret-name> <kube-context>"
  echo "Example: $0 ap-south-1 123456789012 streaming-brm ecr-pull-secret kind-kind"
  exit 1
fi

AWS_REGION="$1"
AWS_ACCOUNT_ID="$2"
NAMESPACE="$3"
SECRET_NAME="$4"
KUBE_CONTEXT="$5"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

kubectl config use-context "${KUBE_CONTEXT}" >/dev/null

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}" >/dev/null

ECR_PASSWORD="$(aws ecr get-login-password --region "${AWS_REGION}")"

kubectl -n "${NAMESPACE}" delete secret "${SECRET_NAME}" >/dev/null 2>&1 || true
kubectl -n "${NAMESPACE}" create secret docker-registry "${SECRET_NAME}" \
  --docker-server="${ECR_REGISTRY}" \
  --docker-username=AWS \
  --docker-password="${ECR_PASSWORD}" >/dev/null

kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null
echo "Created/updated imagePullSecret '${SECRET_NAME}' in namespace '${NAMESPACE}' for registry '${ECR_REGISTRY}'."

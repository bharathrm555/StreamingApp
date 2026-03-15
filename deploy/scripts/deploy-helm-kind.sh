#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 8 ]]; then
  echo "Usage: $0 <aws-region> <aws-account-id> <image-tag> <public-base-url> <public-hostname> <namespace> <release-name> <kube-context>"
  echo "Example: $0 ap-south-1 123456789012 v1 http://streamingapp.local streamingapp.local streaming-brm streamingapp-brm kind-kind"
  exit 1
fi

AWS_REGION="$1"
AWS_ACCOUNT_ID="$2"
IMAGE_TAG="$3"
PUBLIC_BASE_URL="${4%/}"
PUBLIC_HOSTNAME="$5"
NAMESPACE="$6"
RELEASE_NAME="$7"
KUBE_CONTEXT="$8"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPOSITORY="streamingapp-brm"
PULL_SECRET_NAME="${IMAGE_PULL_SECRET_NAME:-ecr-pull-secret}"

kubectl config use-context "${KUBE_CONTEXT}" >/dev/null

helm upgrade --install "${RELEASE_NAME}" ./deploy/helm/streamingapp \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set image.registry="${ECR_REGISTRY}" \
  --set image.repository="${ECR_REPOSITORY}" \
  --set image.pullSecrets[0].name="${PULL_SECRET_NAME}" \
  --set image.tags.auth="auth-${IMAGE_TAG}" \
  --set image.tags.streaming="streaming-${IMAGE_TAG}" \
  --set image.tags.admin="admin-${IMAGE_TAG}" \
  --set image.tags.chat="chat-${IMAGE_TAG}" \
  --set image.tags.frontend="frontend-${IMAGE_TAG}" \
  --set global.clientUrls[0]="${PUBLIC_BASE_URL}" \
  --set ingress.host="${PUBLIC_HOSTNAME}" \
  --wait --timeout 20m

kubectl get pods -n "${NAMESPACE}"
kubectl get svc -n "${NAMESPACE}"
kubectl get ingress -n "${NAMESPACE}" || true

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 7 ]]; then
  echo "Usage: $0 <aws-region> <cluster-name> <namespace> <release-name> <aws-account-id> <image-tag> <public-hostname>"
  echo "Example: $0 ap-south-1 streaming-eks-brm streaming-brm streamingapp-brm 123456789012 v1 app.example.com"
  exit 1
fi

AWS_REGION="$1"
CLUSTER_NAME="$2"
NAMESPACE="$3"
RELEASE_NAME="$4"
AWS_ACCOUNT_ID="$5"
IMAGE_TAG="$6"
PUBLIC_HOSTNAME="$7"
ECR_REPOSITORY="streamingapp-brm"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

helm upgrade --install "${RELEASE_NAME}" ./deploy/helm/streamingapp \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set image.registry="${ECR_REGISTRY}" \
  --set image.repository="${ECR_REPOSITORY}" \
  --set image.tags.auth="auth-${IMAGE_TAG}" \
  --set image.tags.streaming="streaming-${IMAGE_TAG}" \
  --set image.tags.admin="admin-${IMAGE_TAG}" \
  --set image.tags.chat="chat-${IMAGE_TAG}" \
  --set image.tags.frontend="frontend-${IMAGE_TAG}" \
  --set global.clientUrls[0]="https://${PUBLIC_HOSTNAME}" \
  --set ingress.host="${PUBLIC_HOSTNAME}" \
  --wait --timeout 10m

kubectl get pods -n "${NAMESPACE}"
kubectl get svc -n "${NAMESPACE}"
kubectl get ingress -n "${NAMESPACE}"

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <aws-region> <aws-account-id> <image-tag> <frontend-public-base-url>"
  echo "Example: $0 ap-south-1 123456789012 v1 https://app.example.com"
  exit 1
fi

AWS_REGION="$1"
AWS_ACCOUNT_ID="$2"
IMAGE_TAG="$3"
PUBLIC_BASE_URL="${4%/}"
ECR_REPOSITORY="streamingapp-brm"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE_BASE="${ECR_REGISTRY}/${ECR_REPOSITORY}"

AUTH_TAG="auth-${IMAGE_TAG}"
STREAMING_TAG="streaming-${IMAGE_TAG}"
ADMIN_TAG="admin-${IMAGE_TAG}"
CHAT_TAG="chat-${IMAGE_TAG}"
FRONTEND_TAG="frontend-${IMAGE_TAG}"

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

docker build -t streamingapp-auth-brm:"${AUTH_TAG}" ./backend/authService
docker build -f ./backend/streamingService/Dockerfile -t streamingapp-streaming-brm:"${STREAMING_TAG}" ./backend
docker build -f ./backend/adminService/Dockerfile -t streamingapp-admin-brm:"${ADMIN_TAG}" ./backend
docker build -f ./backend/chatService/Dockerfile -t streamingapp-chat-brm:"${CHAT_TAG}" ./backend
docker build \
  --build-arg REACT_APP_AUTH_API_URL="${PUBLIC_BASE_URL}/api" \
  --build-arg REACT_APP_STREAMING_API_URL="${PUBLIC_BASE_URL}/api/streaming" \
  --build-arg REACT_APP_STREAMING_PUBLIC_URL="${PUBLIC_BASE_URL}" \
  --build-arg REACT_APP_ADMIN_API_URL="${PUBLIC_BASE_URL}/api/admin" \
  --build-arg REACT_APP_CHAT_API_URL="${PUBLIC_BASE_URL}/api/chat" \
  --build-arg REACT_APP_CHAT_SOCKET_URL="${PUBLIC_BASE_URL}" \
  -t streamingapp-frontend-brm:"${FRONTEND_TAG}" ./frontend

docker tag streamingapp-auth-brm:"${AUTH_TAG}" "${ECR_IMAGE_BASE}:${AUTH_TAG}"
docker tag streamingapp-streaming-brm:"${STREAMING_TAG}" "${ECR_IMAGE_BASE}:${STREAMING_TAG}"
docker tag streamingapp-admin-brm:"${ADMIN_TAG}" "${ECR_IMAGE_BASE}:${ADMIN_TAG}"
docker tag streamingapp-chat-brm:"${CHAT_TAG}" "${ECR_IMAGE_BASE}:${CHAT_TAG}"
docker tag streamingapp-frontend-brm:"${FRONTEND_TAG}" "${ECR_IMAGE_BASE}:${FRONTEND_TAG}"

docker push "${ECR_IMAGE_BASE}:${AUTH_TAG}"
docker push "${ECR_IMAGE_BASE}:${STREAMING_TAG}"
docker push "${ECR_IMAGE_BASE}:${ADMIN_TAG}"
docker push "${ECR_IMAGE_BASE}:${CHAT_TAG}"
docker push "${ECR_IMAGE_BASE}:${FRONTEND_TAG}"

echo "Pushed ${ECR_IMAGE_BASE}:${AUTH_TAG}"
echo "Pushed ${ECR_IMAGE_BASE}:${STREAMING_TAG}"
echo "Pushed ${ECR_IMAGE_BASE}:${ADMIN_TAG}"
echo "Pushed ${ECR_IMAGE_BASE}:${CHAT_TAG}"
echo "Pushed ${ECR_IMAGE_BASE}:${FRONTEND_TAG}"

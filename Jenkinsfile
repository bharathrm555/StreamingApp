pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region for ECR/EKS')
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '975050024946', description: '12-digit AWS account ID')
    string(name: 'AWS_CREDENTIALS_ID', defaultValue: '975050024946', description: 'Jenkins AWS credentials ID')
    string(name: 'ECR_REPOSITORY', defaultValue: 'streamingapp-brm', description: 'Single ECR repository name')
    string(name: 'EKS_CLUSTER_NAME', defaultValue: 'streaming-eks-brm', description: 'EKS cluster name')
    string(name: 'K8S_NAMESPACE', defaultValue: 'streaming-brm', description: 'Kubernetes namespace')
    string(name: 'HELM_RELEASE', defaultValue: 'streamingapp-brm', description: 'Helm release name')
    string(name: 'IMAGE_TAG', defaultValue: 'v1', description: 'Leave blank to use BUILD_NUMBER')
    string(name: 'FRONTEND_PUBLIC_BASE_URL', defaultValue: 'http://localhost:3000', description: 'Public URL used by frontend build args (example: https://app.example.com)')
    booleanParam(name: 'DEPLOY_TO_EKS', defaultValue: true, description: 'Deploy to EKS with Helm after push')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Preflight') {
      steps {
        script {
          env.AWS_ACCOUNT_ID = params.AWS_ACCOUNT_ID
          env.AWS_REGION = params.AWS_REGION

          env.BUILD_TAG_RESOLVED = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : env.BUILD_NUMBER
          env.ECR_REGISTRY = "${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com"
          env.ECR_IMAGE_BASE = "${env.ECR_REGISTRY}/${params.ECR_REPOSITORY}"
          env.AUTH_TAG = "auth-${env.BUILD_TAG_RESOLVED}"
          env.STREAMING_TAG = "streaming-${env.BUILD_TAG_RESOLVED}"
          env.ADMIN_TAG = "admin-${env.BUILD_TAG_RESOLVED}"
          env.CHAT_TAG = "chat-${env.BUILD_TAG_RESOLVED}"
          env.FRONTEND_TAG = "frontend-${env.BUILD_TAG_RESOLVED}"
          env.INGRESS_HOST = params.FRONTEND_PUBLIC_BASE_URL
            .replaceFirst('^https?://', '')
            .replaceFirst('/.*$', '')
        }
        sh '''#!/usr/bin/env bash
          set -euxo pipefail
          test -n "${AWS_ACCOUNT_ID}"
          docker --version
          aws --version
          helm version
          kubectl version --client
        '''
      }
    }

    stage('AWS Login + Ensure ECR Repo') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${params.AWS_CREDENTIALS_ID}"]]) {
          sh '''#!/usr/bin/env bash
            set -euxo pipefail
            aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
            aws ecr describe-repositories --region "${AWS_REGION}" --repository-names "${ECR_REPOSITORY}" >/dev/null 2>&1 || \
            aws ecr create-repository --region "${AWS_REGION}" --repository-name "${ECR_REPOSITORY}" >/dev/null
          '''
        }
      }
    }

    stage('Build Images') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euxo pipefail

          docker build -t "streamingapp-auth-brm:${AUTH_TAG}" ./backend/authService
          docker build -f ./backend/streamingService/Dockerfile -t "streamingapp-streaming-brm:${STREAMING_TAG}" ./backend
          docker build -f ./backend/adminService/Dockerfile -t "streamingapp-admin-brm:${ADMIN_TAG}" ./backend
          docker build -f ./backend/chatService/Dockerfile -t "streamingapp-chat-brm:${CHAT_TAG}" ./backend

          BASE_URL="${FRONTEND_PUBLIC_BASE_URL%/}"
          docker build \
            --build-arg REACT_APP_AUTH_API_URL="${BASE_URL}/api" \
            --build-arg REACT_APP_STREAMING_API_URL="${BASE_URL}/api/streaming" \
            --build-arg REACT_APP_STREAMING_PUBLIC_URL="${BASE_URL}" \
            --build-arg REACT_APP_ADMIN_API_URL="${BASE_URL}/api/admin" \
            --build-arg REACT_APP_CHAT_API_URL="${BASE_URL}/api/chat" \
            --build-arg REACT_APP_CHAT_SOCKET_URL="${BASE_URL}" \
            -t "streamingapp-frontend-brm:${FRONTEND_TAG}" ./frontend
        '''
      }
    }

    stage('Push Images To Single ECR Repo') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euxo pipefail

          docker tag "streamingapp-auth-brm:${AUTH_TAG}" "${ECR_IMAGE_BASE}:${AUTH_TAG}"
          docker tag "streamingapp-streaming-brm:${STREAMING_TAG}" "${ECR_IMAGE_BASE}:${STREAMING_TAG}"
          docker tag "streamingapp-admin-brm:${ADMIN_TAG}" "${ECR_IMAGE_BASE}:${ADMIN_TAG}"
          docker tag "streamingapp-chat-brm:${CHAT_TAG}" "${ECR_IMAGE_BASE}:${CHAT_TAG}"
          docker tag "streamingapp-frontend-brm:${FRONTEND_TAG}" "${ECR_IMAGE_BASE}:${FRONTEND_TAG}"

          docker push "${ECR_IMAGE_BASE}:${AUTH_TAG}"
          docker push "${ECR_IMAGE_BASE}:${STREAMING_TAG}"
          docker push "${ECR_IMAGE_BASE}:${ADMIN_TAG}"
          docker push "${ECR_IMAGE_BASE}:${CHAT_TAG}"
          docker push "${ECR_IMAGE_BASE}:${FRONTEND_TAG}"
        '''
      }
    }

    stage('Deploy To EKS (Helm)') {
      when {
        expression { return params.DEPLOY_TO_EKS }
      }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${params.AWS_CREDENTIALS_ID}"]]) {
          sh '''#!/usr/bin/env bash
            set -euxo pipefail

            aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME}" --region "${AWS_REGION}"

            helm upgrade --install "${HELM_RELEASE}" ./deploy/helm/streamingapp \
              --namespace "${K8S_NAMESPACE}" \
              --create-namespace \
              --set image.registry="${ECR_REGISTRY}" \
              --set image.repository="${ECR_REPOSITORY}" \
              --set image.tags.auth="${AUTH_TAG}" \
              --set image.tags.streaming="${STREAMING_TAG}" \
              --set image.tags.admin="${ADMIN_TAG}" \
              --set image.tags.chat="${CHAT_TAG}" \
              --set image.tags.frontend="${FRONTEND_TAG}" \
              --set global.clientUrls[0]="${FRONTEND_PUBLIC_BASE_URL}" \
              --set ingress.host="${INGRESS_HOST}" \
              --wait --timeout 10m

            kubectl get pods -n "${K8S_NAMESPACE}"
            kubectl get svc -n "${K8S_NAMESPACE}"
            kubectl get ingress -n "${K8S_NAMESPACE}" || true
          '''
        }
      }
    }
  }

  post {
    always {
      sh '''#!/usr/bin/env bash
        docker image prune -f || true
      '''
    }
    success {
      echo "Build and deployment completed for build tag: ${BUILD_TAG_RESOLVED}"
    }
    failure {
      echo 'Pipeline failed. Check stage logs for details.'
    }
  }
}

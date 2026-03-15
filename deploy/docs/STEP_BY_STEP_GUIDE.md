# StreamingApp Assignment: Simple Step-by-Step (Single ECR Repo + BRM Suffix)

This guide is simplified to meet your requirement with minimal moving parts.

## 1) Where the required files are

- Jenkins pipeline: `Jenkinsfile`
- Helm chart: `deploy/helm/streamingapp`
- Main Helm values: `deploy/helm/streamingapp/values.yaml`
- Helper scripts:
  - `deploy/scripts/create-ecr-repos.sh`
  - `deploy/scripts/build-and-push.sh`
  - `deploy/scripts/deploy-helm.sh` (EKS flow)
  - `deploy/scripts/create-k8s-ecr-pull-secret.sh` (kind/local flow)

All new Kubernetes resources use `-brm` suffix.

## 1.1) If you are deploying to local kind (instead of EKS)

Use the dedicated guide:
- `deploy/docs/KIND_STEP_BY_STEP_GUIDE.md`

## 2) Tool check on your machine

Run:
```bash
aws --version
docker --version
kubectl version --client
helm version
eksctl version
```

Expected: each command prints a version.

## 3) Configure AWS CLI

Run:
```bash
aws configure
aws sts get-caller-identity
```

Expected: JSON output with your AWS Account ID.

## 4) Create single ECR repository

From repo root:
```bash
cd /home/ubuntu/Documents/HVRD_projects/Project_1/StreamingApp
./deploy/scripts/create-ecr-repos.sh ap-south-1 <AWS_ACCOUNT_ID>
```

Expected:
- `Created ECR repository: streamingapp-brm` or
- `ECR repository exists: streamingapp-brm`

## 5) Build and push all images into that single ECR repo

Run:
```bash
./deploy/scripts/build-and-push.sh ap-south-1 <AWS_ACCOUNT_ID> v1 https://app.example.com
```

Expected pushed tags in one repo:
- `auth-v1`
- `streaming-v1`
- `admin-v1`
- `chat-v1`
- `frontend-v1`

Verify in AWS Console -> ECR -> `streamingapp-brm` -> Images.

## 6) Create EKS cluster (if not already created)

Run:
```bash
eksctl create cluster -f deploy/eks/cluster-config.yaml
```

Expected: success logs and cluster name `streaming-eks-brm`.

Then:
```bash
aws eks update-kubeconfig --name streaming-eks-brm --region ap-south-1
kubectl get nodes
```

Expected: nodes in `Ready` status.

## 7) Install ingress controller

Run:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
kubectl get svc -n ingress-nginx
```

Expected: `ingress-nginx-controller` service with external address.

## 8) Deploy app with Helm (all resources with BRM suffix)

Run:
```bash
./deploy/scripts/deploy-helm.sh ap-south-1 streaming-eks-brm streaming-brm streamingapp-brm <AWS_ACCOUNT_ID> v1 app.example.com
```

Expected:
- `Release "streamingapp-brm" has been upgraded/installed`
- Pods running in namespace `streaming-brm`
- Services like `streamingapp-auth-brm`, `streamingapp-frontend-brm`, etc.
- Ingress host `app.example.com`

## 9) DNS mapping

Point `app.example.com` to ingress controller LB DNS.

Check:
```bash
kubectl get ingress -n streaming-brm
```

Expected: ingress `streamingapp-brm` with host `app.example.com`.

## 10) Configure your hosted Jenkins (as provided in assignment)

Jenkins URL from assignment: `https://jenkinsacademics.herovired.com/`

Create a Pipeline job:
- Pipeline from SCM -> your fork repo
- Script Path: `Jenkinsfile`

Set parameters:
- `AWS_REGION`: `ap-south-1`
- `AWS_ACCOUNT_ID`: your account id
- `AWS_CREDENTIALS_ID`: `aws-creds`
- `ECR_REPOSITORY`: `streamingapp-brm`
- `EKS_CLUSTER_NAME`: `streaming-eks-brm`
- `K8S_NAMESPACE`: `streaming-brm`
- `HELM_RELEASE`: `streamingapp-brm`
- `IMAGE_TAG`: blank or e.g. `v2`
- `FRONTEND_PUBLIC_BASE_URL`: `https://app.example.com`
- `DEPLOY_TO_EKS`: `true`

Expected Jenkins stages:
- Checkout
- Preflight
- AWS Login + Ensure ECR Repo
- Build Images
- Push Images To Single ECR Repo
- Deploy To EKS (Helm)

## 11) Final validation for submission

Run:
```bash
kubectl get pods -n streaming-brm
kubectl get svc -n streaming-brm
kubectl get ingress -n streaming-brm
```

Expected:
- all pods running
- services created
- ingress available

Browser validation:
- frontend opens
- auth works
- streaming/admin/chat APIs reachable via `/api/...`

## 12) Scaling evidence

Enable HPA in `deploy/helm/streamingapp/values.yaml`:
- `services.<name>.hpa.enabled: true`

Then apply:
```bash
helm upgrade --install streamingapp-brm ./deploy/helm/streamingapp -n streaming-brm
kubectl get hpa -n streaming-brm
```

Expected: HPA objects created.

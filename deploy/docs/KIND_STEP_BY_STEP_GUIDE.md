# StreamingApp Assignment: Step-by-Step (Single ECR Repo + Local kind + Local Jenkins)

This flow matches your updated plan:
- Jenkins runs locally, builds Docker images and pushes them to a single ECR repository with multiple tags.
- A local Kubernetes cluster (kind) pulls those images from ECR and runs the app via Helm.

## 0) Important note about Jenkins choice

Only a Jenkins that can reach your local kubeconfig can deploy to kind.
- Local Jenkins: OK.
- Hosted Jenkins (like `https://jenkinsacademics.herovired.com/`): cannot access your laptop kind cluster.

## 1) Tool check (local machine + Jenkins agent)

Make sure these are installed on the machine where Jenkins pipeline runs:
```bash
aws --version
docker --version
kubectl version --client
helm version
kind version
```

## 2) AWS auth sanity check

```bash
aws sts get-caller-identity
aws ecr describe-repositories --region ap-south-1 --max-items 1 >/dev/null
```

## 3) Create kind cluster (expose ports 80/443)

From repo root:
```bash
cd /home/bharath/Documents/HVRD_projects/Project_1/StreamingApp
kind create cluster --config deploy/kind/kind-config.yaml
kubectl config use-context kind-kind
kubectl get nodes
```

## 4) Install ingress-nginx (kind)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=5m
```

## 5) Pick your local hostname

Use a local host for ingress, for example:
- `streamingapp.local`

Add it to your hosts file pointing to localhost:
```bash
sudo sh -c 'echo "127.0.0.1 streamingapp.local" >> /etc/hosts'
```

## 6) Create the single ECR repository

```bash
./deploy/scripts/create-ecr-repos.sh ap-south-1 <AWS_ACCOUNT_ID>
```

Expected repo: `streamingapp-brm`

## 7) Build and push all images into the single ECR repo

This bakes the public base URL into the frontend build:
```bash
./deploy/scripts/build-and-push.sh ap-south-1 <AWS_ACCOUNT_ID> v1 http://streamingapp.local
```

Expected pushed tags in one repo:
- `auth-v1`
- `streaming-v1`
- `admin-v1`
- `chat-v1`
- `frontend-v1`

## 8) Create Kubernetes imagePullSecret for ECR

ECR tokens expire periodically; recreate when pulls start failing.
```bash
./deploy/scripts/create-k8s-ecr-pull-secret.sh ap-south-1 <AWS_ACCOUNT_ID> streaming-brm ecr-pull-secret kind-kind
```

## 9) Deploy to kind using Helm

Note: MongoDB persistence is disabled by default for kind (`mongo.persistence.enabled: false`) to avoid PVCs stuck in `Pending` on clusters without a default StorageClass.

If you prefer a script:
```bash
./deploy/scripts/deploy-helm-kind.sh ap-south-1 <AWS_ACCOUNT_ID> v1 http://streamingapp.local streamingapp.local streaming-brm streamingapp-brm kind-kind
```

Or run Helm directly:
```bash
helm upgrade --install streamingapp-brm ./deploy/helm/streamingapp \
  --namespace streaming-brm --create-namespace \
  --set image.registry=<AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com \
  --set image.repository=streamingapp-brm \
  --set image.pullSecrets[0].name=ecr-pull-secret \
  --set image.tags.auth=auth-v1 \
  --set image.tags.streaming=streaming-v1 \
  --set image.tags.admin=admin-v1 \
  --set image.tags.chat=chat-v1 \
  --set image.tags.frontend=frontend-v1 \
  --set global.clientUrls[0]=http://streamingapp.local \
  --set ingress.host=streamingapp.local
```

Validate:
```bash
kubectl get pods -n streaming-brm
kubectl get svc -n streaming-brm
kubectl get ingress -n streaming-brm
```

## 10) Access the app

If ingress is installed and `/etc/hosts` is set:
- Open `http://streamingapp.local`

If you want a quick bypass (no ingress), use port-forward:
```bash
kubectl -n streaming-brm port-forward svc/streamingapp-frontend-brm 8080:80
```
Then open `http://localhost:8080` (note: frontend base URL should match what you baked at build time).

## 11) Jenkins pipeline parameters (local Jenkins)

Use the repo root `Jenkinsfile` and set:
- `AWS_REGION`: `ap-south-1`
- `AWS_ACCOUNT_ID`: your account id
- `AWS_CREDENTIALS_ID`: your Jenkins AWS credentials id
- `ECR_REPOSITORY`: `streamingapp-brm`
- `KUBE_CONTEXT`: `kind-kind`
- `K8S_NAMESPACE`: `streaming-brm`
- `HELM_RELEASE`: `streamingapp-brm`
- `IMAGE_PULL_SECRET_NAME`: `ecr-pull-secret`
- `FRONTEND_PUBLIC_BASE_URL`: `http://streamingapp.local`
- `DEPLOY_TO_K8S`: `true`

For automatic builds:
- Enable SCM polling or webhook (depends on your Git hosting and Jenkins setup).

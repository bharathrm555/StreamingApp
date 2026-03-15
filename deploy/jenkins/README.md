# Jenkins Setup Notes (Local Jenkins + kind)

Use a Jenkins instance that runs on the same machine (or network) that can reach your local kubeconfig and `kind` cluster.

## Required plugins on Jenkins
- Pipeline
- Git
- Docker Pipeline
- AWS Credentials

## Required tools on Jenkins agent/node
- Docker
- AWS CLI v2
- kubectl
- helm
- kind (only needed if Jenkins will create the cluster)

## Pipeline source
Use the root `Jenkinsfile` from this repository.

## Required Jenkins credential
- Type: AWS Credentials
- ID: `aws-creds` (or pass your custom ID via `AWS_CREDENTIALS_ID` parameter)

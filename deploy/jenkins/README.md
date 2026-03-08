# Jenkins Setup Notes (Hosted Jenkins)

Use your provided Jenkins server and create a Pipeline job that points to this repository.

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

## Pipeline source
Use the root `Jenkinsfile` from this repository.

## Required Jenkins credential
- Type: AWS Credentials
- ID: `aws-creds` (or pass your custom ID via `AWS_CREDENTIALS_ID` parameter)

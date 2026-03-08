# StreamingApp Helm Chart (BRM)

## Chart location
`deploy/helm/streamingapp`

## Files you will edit most often
- `deploy/helm/streamingapp/values.yaml`
- `deploy/helm/streamingapp/templates/secret.yaml`
- `deploy/helm/streamingapp/templates/ingress.yaml`

## Deploy command
```bash
helm upgrade --install streamingapp-brm ./deploy/helm/streamingapp \
  --namespace streaming-brm --create-namespace \
  --set image.registry=<aws_account_id>.dkr.ecr.<region>.amazonaws.com \
  --set image.repository=streamingapp-brm \
  --set image.tags.auth=auth-v1 \
  --set image.tags.streaming=streaming-v1 \
  --set image.tags.admin=admin-v1 \
  --set image.tags.chat=chat-v1 \
  --set image.tags.frontend=frontend-v1 \
  --set global.clientUrls[0]=https://<public-host> \
  --set ingress.host=<public-host>
```

## Quick checks
```bash
kubectl get pods -n streaming-brm
kubectl get svc -n streaming-brm
kubectl get ingress -n streaming-brm
```

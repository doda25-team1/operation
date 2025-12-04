# SMS App - Kubernetes Deployment

## Requirements
- Kubernetes cluster
- Helm
- kubectl

## Installation

### Default Install
```bash
helm install sms-app ./helm
```

### Custom Domain
```bash
helm install sms-app ./helm \
  --set app.ingress.hostname=your-domain.com \
  --set app.image.repository=ghcr.io/doda25-team1/app \
  --set app.image.tag=latest
```

## Configurable Settings
- `app.ingress.hostname`: URL for accessing the app (default: sms-app.example.com)
- `app.image.repository`: Docker image (default: ghcr.io/doda25-team1/app)
- `app.image.tag`: Version to deploy (default: latest)
- `app.replicaCount`: Number of app copies (default: 2)

## How to Access

Check ingress:
```bash
kubectl get ingress
```

Test locally:
```bash
kubectl port-forward service/sms-app-doda-sms-app-app 8080:8080
```
Go to http://localhost:8080

## How to Remove
```bash
helm uninstall sms-app
```



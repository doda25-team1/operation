# SMS App - Kubernetes Deployment

## Requirements
- Kubernetes cluster (Vagrant VMs or Minikube)
- Helm 3
- kubectl
- Istio

## Installation

### Option 1: Using Vagrant Cluster

1. **Start the Vagrant cluster** (if not already running):
```bash
cd /path/to/operation
vagrant up
```

2. **SSH into the controller VM**:
```bash
vagrant ssh ctrl
```

3. **Install the Helm chart** (from inside the VM):
```bash
helm install sms-app /vagrant/helm
```

4. **Wait for pods to be ready**:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=sms-app --timeout=300s
```

### Option 2: Using Host Machine

1. **Configure kubectl** to use the Vagrant cluster:
```bash
export KUBECONFIG="/path/to/operation/.kube/config"
```

2. **Install the Helm chart**:
```bash
helm install sms-app ./helm
```

### Custom Configuration

Install with custom settings:
```bash
helm install sms-app ./helm \
  --set app.ingress.hostname=your-domain.com \
  --set app.image.tag=v2.0.0 \
  --set app.replicaCount=3 \
  --set istio.gateway.name=custom-gateway
```

## Istio Gateway

### Default Gateway

By default:
- Gateway name: `istio-ingressgateway`
- Namespace: `istio-system`
- Selector: `istio: ingressgateway`

### Custom Gateway

If your cluster has different gateway name, when installing override the default values:

```bash
helm install sms-app ./helm \
  --set istio.gateway.name=random-blah-blah-gateway-name \
  --set istio.gateway.namespace=random-blah-blah-namespace
```

### Turn off

Deploy without Istio, to skip creating Gateway and VirtualService:
```bash
helm install sms-app ./helm --set istio.enabled=false
```

## Verifying the Deployment

### 1. Check All Resources

```bash
# Check deployments
kubectl get deployments -l app.kubernetes.io/instance=sms-app

# Check services
kubectl get services -l app.kubernetes.io/instance=sms-app

# Check pods
kubectl get pods -l app.kubernetes.io/instance=sms-app

# Check ingress
kubectl get ingress
```

Expected output:
- 2 deployments (app and model-service)
- 2 services
- 3 pods total (2 app replicas + 1 model-service)
- 1 ingress

### 2. Verify MODEL_HOST Environment Variable

This verifies that the app knows how to connect to the model-service:

```bash
# Get the app pod name and store into variable APP_POD
APP_POD=$(kubectl get pods -l app.kubernetes.io/component=app -o jsonpath='{.items[0].metadata.name}')

# Check the MODEL_HOST environment variable
kubectl exec $APP_POD -- env | grep MODEL_HOST
```

Expected output: `MODEL_HOST=http://sms-app-doda-sms-app-model:8081`

### 3. Test App-to-Model-Service Connectivity

Verify the app can communicate with the model-service using Kubernetes DNS:

```bash
# Test HTTP connectivity
kubectl exec $APP_POD -- curl -s http://sms-app-doda-sms-app-model:8081/apidocs | head -10
```

Expected: curl should return HTML content.

### 4. Test End-to-End Functionality

Access the application and verify it works:

```bash
# Port-forward to access locally
kubectl port-forward service/sms-app-doda-sms-app-app 8080:8080 &

# Test the homepage
curl http://localhost:8080/

# Stop port-forward
pkill -f "port-forward"
```

### Monitoring & Alerting
- Prometheus + Alertmanager are deployed via the Prometheus Operator CRDs (toggle with `monitoring.enabled`).
- ServiceMonitor (`monitor.yaml`) scrapes `/sms/metrics` on the app service using the `release` label `sms-app-prom`.
- High traffic alert: `HighRequestRate` fires when `app_http_requests_total` exceeds the configured per-minute threshold for 2 minutes (`monitoring.rules.requestRate.*`).
- Default receiver posts to `http://alert-logger.default.svc.cluster.local:8080/` (override in `monitoring.alertmanager.config.webhookUrl`).
- Optional email receiver: set `monitoring.alertmanager.email.enabled=true`, fill `to/from/smarthost/username` and `password`; password is stored in a Secret and mounted into Alertmanager.
- Access UIs for quick checks:
  - Prometheus: `kubectl port-forward svc/<release>-doda-sms-app-prometheus 9090:9090`
  - Alertmanager: `kubectl port-forward svc/<release>-doda-sms-app-alertmanager 9093:9093`

## Configurable Settings

### Basic Settings
- `app.ingress.hostname`: URL for accessing the app (default: `sms-app.example.com`)
- `app.image.repository`: Docker image repository (default: `ghcr.io/doda25-team1/app`)
- `app.image.tag`: Version to deploy (default: `latest`)
- `app.replicaCount`: Number of app replicas (default: `2`)

### Model Service Settings
- `modelService.image.repository`: Model service image (default: `ghcr.io/doda25-team1/model-service`)
- `modelService.image.tag`: Model service version (default: `latest`)
- `modelService.env.MODEL_VERSION`: Model version to download (default: `0.0.1`)
- `modelService.env.MODEL_BASE_URL`: Base URL for model downloads (default: GitHub releases URL)

### ConfigMap and Secret (Optional)
- `app.config.enabled`: Enable ConfigMap (default: `false`)
- `app.config.value`: ConfigMap placeholder value
- `app.secret.enabled`: Enable Secret (default: `false`)
- `app.secret.smtpPassword`: Secret placeholder value (change during installation)

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=sms-app

# Check logs for failed pods
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>
```

### Model-Service CrashLoopBackOff

Common issue: MODEL_BASE_URL is incorrect. Ensure it points to a valid GitHub releases URL:
```bash
kubectl get deployment sms-app-doda-sms-app-model -o yaml | grep MODEL_BASE_URL
```

Should be: `https://github.com/doda25-team1/model-service/releases/download`

### Cannot Connect to Cluster (from host)

```bash
# Verify VMs are running
vagrant status

# Ensure KUBECONFIG is set
export KUBECONFIG="/path/to/operation/.kube/config"

# Test connection
kubectl get nodes
```

## How to Remove

```bash
helm uninstall sms-app

# Verify all resources deleted
kubectl get all -l app.kubernetes.io/instance=sms-app
```

# SMS Spam Checker

A cloud-native SMS spam detection application deployed on Kubernetes with Istio service mesh, featuring ML-based classification, traffic management, and observability.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Component Details](#component-details)
- [Quick Start (Docker Compose)](#quick-start-docker-compose)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Istio Service Mesh](#istio-service-mesh)
- [Monitoring & Observability](#monitoring--observability)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
                                External Traffic

                                        │
                                        V

                                Istio Ingress Gateway        

                                        │
                                        V
                                VirtualService                                     
                    (Routes traffic, canary splits: 90% v1 / 10% v2)  

                                 │                   │
                        ┌────────┘                   └────────┐
                        V                                     V

      App Service (v1)                                   App Service (v2)         
   - Spring Boot frontend                             - Experimental version      
   - Web UI + REST API                                - Canary testing            
   - 2 replicas (default)                                           

            │
            V

       Model Service           
   - Python Flask backend      
   - ML spam detection         
   - Decision tree classifier  
   - 1 replica (default)       

```

The SMS Spam Checker consists of three main components:

| Component | Description |
|-----------|-------------|
| [**app-service**](../app) | Frontend application serving web UI and REST API gateway |
| [**model-service**](../model-service) | ML backend providing spam detection predictions |
| [**lib-version**](../lib-version) | Shared utility exposing package version at runtime |

---

## Project Structure

```
operation/
├── docker-compose.yml       # Local development with Docker
├── Vagrantfile              # VM provisioning for K8s cluster
├── inventory_portforward.ini # Ansible inventory for host provisioning
│
├── helm/                    # Helm chart for Kubernetes deployment
│   ├── Chart.yaml           # Chart metadata
│   ├── values.yaml          # Configurable parameters
│   └── templates/           # Kubernetes manifests
│       ├── app-deployment.yaml
│       ├── app-service.yaml
│       ├── model-deployment.yaml
│       ├── model-service.yaml
│       ├── gateway.yaml          # Istio Gateway
│       ├── app-virtualservice.yaml
│       ├── app-destinationrule.yaml
│       ├── ingress.yaml
│       └── ... (monitoring, RBAC, etc.)
│
├── playbooks/               # Ansible playbooks for cluster setup
│   ├── general.yml          # Common setup (Docker, kubeadm, etc.)
│   ├── ctrl.yml             # Controller node setup
│   ├── node.yml             # Worker node setup
│   └── finalization.yml     # MetalLB, Ingress, Dashboard, Istio
│
├── docs/                    # Additional documentation
│   ├── deployment.md
│   ├── continuous-experimentation.md
│   └── extension.md
│
└── ssh-keys/                # SSH public keys for VM access
```

---

## Component Details

### App Service (Frontend)

The app-service is a **Spring Boot** application that:

- Serves the web UI at `/sms/`
- Acts as an API gateway, forwarding prediction requests to model-service
- Exposes Prometheus metrics at `/sms/metrics`
- Requires `MODEL_HOST` environment variable to locate backend

**Metrics Exposed:**
| Metric | Type | Description |
|--------|------|-------------|
| `app_http_requests_total` | Counter | Total HTTP requests by endpoint and status |
| `app_active_requests` | Gauge | Current concurrent requests |
| `app_http_request_duration_seconds` | Histogram | Request latency distribution |

### Model Service (Backend)

The model-service is a **Python Flask** application that:

- Provides spam detection via ML (Decision Tree classifier)
- Downloads model files from GitHub releases at startup
- Exposes API documentation at `/apidocs`
- Serves predictions via `POST /predict`

**Environment Variables:**
| Variable | Example | Description |
|----------|---------|-------------|
| `MODEL_VERSION` | `2.0.1` | Model version to download from releases |
| `MODEL_BASE_URL` | `https://github.com/doda25-team1/model-service/releases/download` | Base URL for model downloads |


---

## Quick Start (Docker Compose)

### Steps

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Add/Edit .env if needed
   ```

2. **Start services:**
   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   - Web UI: http://localhost:8080/sms/

4. **View logs:**
   ```bash
   docker-compose logs -f app-service
   docker-compose logs -f model-service
   ```

5. **Stop services:**
   ```bash
   docker-compose down
   ```

---

## Kubernetes Deployment

### Prerequisites

- VirtualBox
- Vagrant
- kubectl (on host machine)
- Ansible

### Cluster Architecture

The Vagrant setup provisions a 3-node Kubernetes cluster:

| Node | IP | Resources | Role |
|------|-----|-----------|------|
| ctrl | 192.168.56.100 | 4GB RAM, 2 CPU | Control plane |
| node-1 | 192.168.56.101 | 6GB RAM, 2 CPU | Worker |
| node-2 | 192.168.56.102 | 6GB RAM, 2 CPU | Worker |

### Step 1: Provision the Cluster

```bash
cd operation
vagrant up
```

This runs the Ansible playbooks to:
- Install containerd + runc as the runtime and kubeadm/kubelet/kubectl (v1.32.4)
- Configure kubelet node IPs via /etc/default/kubelet to bind to eth1
- Initialize the Kubernetes cluster on `ctrl`
- Join worker nodes to the cluster
- Install Flannel CNI for pod networking

**Shared Storage:** All VMs automatically mount the host's `./shared` folder at `/mnt/shared`. This enables shared storage across all Kubernetes nodes via hostPath volumes, allowing pods on different nodes to access the same data (e.g., model files).

### Step 2: Verify Cluster

SSH into the controller:
```bash
vagrant ssh ctrl
kubectl get nodes
```

Expected output:
```
ctrl     Ready    control-plane   5m    v1.32.x
node-1   Ready                    4m    v1.32.x
node-2   Ready                    3m    v1.32.x
```

### Step 3: Finalize Cluster Setup

Run the finalization playbook from your host machine (after `vagrant up`, using the Vagrant-provided SSH key/port-forward in `inventory_portforward.ini`):
```bash
cd operation
ansible-playbook -i inventory_portforward.ini playbooks/finalization.yml
# if by some chance the previous command failed, try:
# ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory playbooks/finalization.yml
```

This installs:
- **MetalLB**: LoadBalancer for bare-metal (IP pool: 192.168.56.90-99)
- **NGINX Ingress Controller**: HTTP/HTTPS routing
- **Kubernetes Dashboard**: Web UI for cluster management
- **Istio Service Mesh**: Traffic management and observability

### Step 4: Deploy Application with Helm

```bash
vagrant ssh ctrl
helm install sms-app /vagrant/helm
```

### Step 5: Verify Deployment

```bash
kubectl get pods
kubectl get services
kubectl get ingress
```

Expected:
- 2 app-service pods (v1)
- 1 model-service pod
- ClusterIP services for both
- Ingress configured

### Using kubectl from Host Machine

The kubeconfig is copied to `operation/.kube/config`:

```bash
export KUBECONFIG="$(pwd)/.kube/config"
kubectl get nodes
```

---

## Istio Service Mesh

Istio provides advanced traffic management, security, and observability.

### Features Enabled

| Feature | Description |
|---------|-------------|
| **Ingress Gateway** | External traffic entry point |
| **VirtualService** | Traffic routing rules |
| **DestinationRule** | Load balancing, circuit breaking |
| **Traffic Splitting** | Canary releases (90/10 split) |
| **Sticky Sessions** | Consistent hashing via `x-user-id` header |
| **Rate Limiting** | Per-user limits via EnvoyFilter + ratelimit service |

### Traffic Flow

1. Request hits **Istio Ingress Gateway** (192.168.56.95:80) with `Host` header:
   * `sms-app.example.com` -> normal split (90/10, sticky by `x-user-id`)
   * `experimental.sms-app.example.com` -> force v2
2. **VirtualService** routes based on weights or host match.
3. **DestinationRule** applies consistent-hash stickiness on `x-user-id`.
4. App-service calls model-service; model VirtualService routes by source pod label (v1 -> model-v1, v2 -> model-v2).
5. EnvoyFilter enforces per-user rate limit (8 req/min) via ratelimit service + Redis.

### Configuration (values.yaml)

```yaml
istio:
  enabled: true
  trafficSplit:
    stable: 90      # % to v1
    experiment: 10  # % to v2
  stickySession:
    headerName: "x-user-id"
  gateway:
    name: "istio-ingressgateway"
    namespace: "istio-system"
    host:
      stable: "sms-app.example.com"
      experimental: "experimental.sms-app.example.com"
  rateLimit:
    enabled: true
```

### Customizing Gateway Name

Override for different clusters:
```bash
helm install sms-app ./helm --set istio.gateway.name=my-custom-gateway
```

### Quick Canary Test (curl)
```bash
export INGRESS_IP=<loadbalancer-ip>
# Stable path (mostly v1, sticky on x-user-id)
curl -H "Host: sms-app.example.com" -H "x-user-id: demo-1" http://$INGRESS_IP/
# Force v2
curl -H "Host: experimental.sms-app.example.com" -H "x-user-id: demo-2" http://$INGRESS_IP/
```

If you reuse the same `x-user-id`, repeat calls stay on the same subset.

---

## Monitoring & Observability

### Prometheus

Scrapes metrics from app-service at `/sms/metrics`.

**Access Prometheus:**
```bash
kubectl port-forward svc/prometheus 9090:9090
# Open http://localhost:9090
```

### Grafana

Visualizes metrics with pre-configured dashboards.

**Access Grafana:**
```bash
kubectl port-forward svc/grafana 3000:3000
# Open http://localhost:3000
# Default: admin / adminPassword
```

### Kubernetes Dashboard

Web UI for cluster management.

**Access Dashboard:**

1. Add to hosts file (`/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`):
   ```
   192.168.56.95  dashboard.local
   ```

2. Get admin token:
   ```bash
   vagrant ssh ctrl -c "kubectl -n kubernetes-dashboard create token admin-user"
   ```

3. Open https://dashboard.local and login with token

---

## Configuration Reference

### Key values.yaml Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `app.replicaCount` | 2 | Number of app-service replicas |
| `app.image.tag` | latest | App container image tag |
| `app.service.port` | 8080 | Service port |
| `app.ingress.hostname` | sms-app.example.com | Ingress hostname |
| `modelService.replicaCount` | 1 | Model service replicas |
| `modelService.env.MODEL_VERSION` | 2.0.1 | ML model version |
| `istio.enabled` | true | Enable Istio resources |
| `istio.trafficSplit.stable` | 90 | % traffic to v1 |
| `istio.gateway.name` | istio-ingressgateway | Gateway name |
| `monitoring.enabled` | false | Enable Prometheus stack |

### Installation Examples

**Basic install:**
```bash
helm install sms-app ./helm
```

**With custom settings:**
```bash
helm install sms-app ./helm \
  --set app.replicaCount=3 \
  --set app.ingress.hostname=myapp.local \
  --set istio.trafficSplit.stable=80 \
  --set istio.trafficSplit.experiment=20
```

**Disable Istio:**
```bash
helm install sms-app ./helm --set istio.enabled=false
```

### Useful Commands

```bash
# Check all pods
kubectl get pods -A

# View pod logs
kubectl logs -f <pod-name>

# Check Istio configuration
istioctl analyze

# Check Ingress Controller pods
vagrant ssh ctrl -c "kubectl get pods -n ingress-nginx"

# Check Ingress Controller service and verify EXTERNAL-IP
vagrant ssh ctrl -c "kubectl get svc -n ingress-nginx"

# Test that the Ingress Controller is responding
vagrant ssh ctrl -c "curl -I http://192.168.56.95"

# Check MetalLB pods are running
vagrant ssh ctrl -c "kubectl get pods -n metallb-system"

# Check MetalLB IP address pool configuration
vagrant ssh ctrl -c "kubectl get ipaddresspool -n metallb-system"

# Check L2Advertisement
vagrant ssh ctrl -c "kubectl get l2advertisement -n metallb-system"
```

### Restart Deployment

```bash
kubectl rollout restart deployment sms-app
kubectl rollout restart deployment sms-model-service
```

---

## Building and Releasing

### Push Images to GitHub Container Registry

1. **Authenticate:**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Build and push app-service:**
   ```bash
   cd ../app
   docker build -t ghcr.io/doda25-team1/app:latest .
   docker push ghcr.io/doda25-team1/app:latest
   ```

3. **Build and push model-service:**
   ```bash
   cd ../model-service
   docker build -t ghcr.io/doda25-team1/model-service:latest .
   docker push ghcr.io/doda25-team1/model-service:latest
   ```


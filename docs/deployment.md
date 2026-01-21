# Deployment Documentation

## 1. Deploying the Application

### Prequisites
*   Minikube running with 4 CPUs and 8GB RAM (`minikube start --cpus 4 --memory 8192`).
*   Istio installed on the cluster.
*   `kubectl` and `helm` installed.

### Installation Steps
To deploy the application components, run the following command from the `operation/helm` directory:

```bash
helm install doda-sms-app . --values values.yaml
```

This will provision:
*   **App Services**: `app-service`, `model-service`.
*   **Deployments**: `app-v1`, `app-v2`, `model-v1`, `model-v2`.
*   **Istio Resources**: `Gateway`, `VirtualService`, `DestinationRule`, `EnvoyFilter`.
*   **Observability**: `ServiceMonitor`, `PrometheusRule`, `Grafana` dashboards.

---

## 2. Deployed Components

The deployment consists of a Kubernetes-based microservices architecture managed by an Istio Service Mesh. The system is divided into several logical layers:

#### High-Level System Overview

```mermaid
flowchart LR
    User([User Requests]) --> Ingress[Istio IngressGateway]
    
    subgraph Cluster [Kubernetes Cluster]
        direction TB
        Ingress --> Mesh[Istio Traffic Mgmt]
        Mesh --> Apps[Application Workloads]
        
        Apps -.-> Observability[Observability Stack]
        Apps -.-> Configs[Configuration]
    end
    
    style User fill:#fff,stroke:#333
    style Ingress fill:#b3e5fc
    style Mesh fill:#e1f5fe
    style Apps fill:#fff3e0
    style Observability fill:#ffebee
    style Configs fill:#f3e5f5
```

### Application Services
*   **app-service (ClusterIP):** The main entry point for the backend logic. It sits in front of the application pods.
    *   **app-deployment (stable):** Runs the `v1` version of the code. Handles ~90% of user traffic.
    *   **app-deployment (canary/experiment):** Runs the `v2` version of the code. Handles ~10% of user traffic for A/B testing.
*   **model-service (ClusterIP):** The internal machine learning service.
    *   **model-deployment (primary):** Serves predictions for the stable app (v1).
    *   **model-deployment (shadow/secondary):** Serves predictions for the experiment app (v2), whilst also acting as a shadow target if configured.

#### Application Services and Deployments

```mermaid
flowchart LR
    subgraph Frontend [App Namespace]
        AppSvc(app-service) 
        AppV1[App v1<br/>Stable]
        AppV2[App v2<br/>Canary]
        
        AppSvc -->|90%| AppV1
        AppSvc -->|10%| AppV2
    end
    
    subgraph Backend [Model Namespace]
        ModelSvc(model-service)
        ModelV1[Model v1<br/>Primary]
        ModelV2[Model v2<br/>Shadow]
        
        ModelSvc --> ModelV1
        ModelSvc -.-> ModelV2
    end
    
    AppV1 -->|Call| ModelSvc
    AppV2 -->|Call| ModelSvc
    
    style AppV1 fill:#e8f5e9
    style AppV2 fill:#fff9c4
    style ModelV1 fill:#e8f5e9
    style ModelV2 fill:#e1bee7
```

### Istio Data Plane
*   **Istio IngressGateway:** An Envoy proxy load balancer that sits at the edge of the cluster, receiving all external HTTP traffic on port 80.
*   **VirtualServices:** Define the routing rules (e.g., traffic splitting, shadow mirroring).
*   **DestinationRules:** Define properties of the upstream clusters, such as consistent hashing for sticky sessions.

#### Istio Traffic Management Layer

```mermaid
flowchart TB
    External(Internet) --> IGW[IngressGateway]
    
    subgraph Routing [Traffic Routing]
        GW(Gateway Object)
        AVS(App VirtualService)
        ADR(App DestinationRule)
    end
    
    IGW --> GW --> AVS
    AVS -->|Consistent Hash| ADR
    
    ADR --> ASvc[app-service]
    
    ASvc --> MVS(Model VirtualService)
    MVS --> MDR(Model DestinationRule)
    MDR --> MS[model-service]
    
    style IGW fill:#b3e5fc
    style AVS fill:#b2dfdb
    style ADR fill:#b2dfdb
    style MVS fill:#b2dfdb
    style MDR fill:#b2dfdb
```

### Observability Stack
*   **Prometheus:** Scrapes metrics from the application pods (via `ServiceMonitor`) and Istio sidecars.
*   **Grafana:** Visualizes metrics (request rates, latency, custom business metrics) on pre-provisioned dashboards.
*   **Alertmanager:** Handles alerting rules (e.g., high error rates).

#### Observability Stack Diagram

```mermaid
flowchart TB
    subgraph Monitoring
        Prom(Prometheus)
        Alert(Alertmanager)
        Graf(Grafana)
    end
    
    Apps[App Pods] -.->|Scrape /metrics| Prom
    
    Prom -->|Firing| Alert
    Graf -->|Query| Prom
    
    style Prom fill:#ffccbc
    style Alert fill:#ffab91
    style Graf fill:#ffe0b2
```

### Configuration Resources

#### Configuration Resources Diagram

```mermaid
flowchart LR
    SharedConfig(ConfigMap) --> AppPods[App Deployments]
    Identity(ServiceAccount) --> AppPods
    Identity --> ModelPods[Model Deployments]
    
    style SharedConfig fill:#e1bee7
    style Identity fill:#ce93d8
```

---

## 3. Request Flow

The life of a request flows through the system as follows:

### Typical Request Path (UI / Predict)

1.  **External Entry:** A user sends an HTTP request to `http://sms-checker.local` (or configured host). The **Istio IngressGateway** intercepts this request.
2.  **Traffic Split (App Layer):** The Gateway forwards the request to the `app` VirtualService.
    *   **Decision:** The VirtualService checks the configured weights (90% vs 10%).
    *   **Sticky Session:** It checks the `x-user-id` header. If present, it uses consistent hashing to ensure the user stays on the same version they were assigned to.
    *   **Result:** The request is routed to either an `app-v1` pod or an `app-v2` pod.
3.  **Internal Service Call:** The application processes the request. When it needs a prediction, it makes an HTTP POST request to `http://model-service:8081`.
    *   **Header Propagation:** Crucially, the application code grabs the `x-app-version` header from the incoming request (e.g., "v1") and injects it into this outgoing request.
4.  **Route Matching (Model Layer):** The `model-service` VirtualService intercepts this internal call.
    *   It inspects the `x-app-version` header.
    *   **If v1:** Routes to the `model-v1` deployment.
    *   **If v2:** Routes to the `model-v2` deployment.
    *   **Result:** Strict isolation is maintained.

### Request Data Flow

The following sequence diagram illustrates the complete request flow from client to services, including routing decisions and shadow mirroring:

```mermaid
sequenceDiagram
    autonumber
    actor User as Client
    participant IGW as IngressGateway
    participant AppVS as App Routing
    participant App as App Service
    participant ModelVS as Model Routing
    participant ModelPrimary as Model v1
    participant ModelShadow as Model v2 (Shadow)

    User->>IGW: HTTP GET / (x-user-id)
    IGW->>AppVS: Forward
    
    Note right of AppVS: 90/10 Split + Sticky Hash
    
    AppVS->>App: Route to v1 or v2
    
    App->>App: Process Logic
    
    App->>ModelVS: POST /predict (x-app-version)
    
    Note right of ModelVS: Route based on x-app-version
    
    par Parallel Execution
        ModelVS->>ModelPrimary: Request (Primary)
        ModelVS->>ModelShadow: Mirror (Shadow)
    end
    
    ModelPrimary-->>App: Response
    App-->>User: Final Response
```

---

## 4. Canary Routing and Sticky Sessions

We implement a **Canary Release** strategy to test `v2` safely.

### Decision Logic
The routing decision is taken by **Envoy at the Istio IngressGateway**, not by application code.
*   **Routing Split**: Approximately 10% of users are routed to the canary subset, while 90% go to stable.
*   **Sticky Sessions**: The `DestinationRule` applies **consistent hashing** on the `x-user-id` HTTP header. This ensures that repeated requests with the same identifier are routed consistently to the same pod version (subset), providing a seamless user experience.

#### Canary Routing Decision Flow

```mermaid
flowchart LR
    Request([User Request]) --> Gate{Gateway Check}
    
    Gate -->|Pass| VS{VirtualService}
    Gate -->|Fail| Drop([Reject])
    
    VS -->|Consistent Hash| DR[DestinationRule]
    
    DR -->|x-user-id| PodSelection
    
    subgraph PodSelection [Pod Assignment]
        direction TB
        Stable[Stable Replicas]
        Canary[Canary Replicas]
    end
    
    DR --> Stable
    DR --> Canary
    
    style Request fill:#fff
    style Stable fill:#c8e6c9
    style Canary fill:#fff9c4
```

---

## 5. Additional Istio Use Case: Rate Limiting

For the advanced infrastructure requirement, we implemented **Global Rate Limiting** using Envoy Filters.

### Implementation Details
*   **Mechanism:** An `EnvoyFilter` injects the `envoy.filters.http.ratelimit` filter into the Gateway listener.
*   **Granularity:** Rate limiting is applied per **Individual User**.
*   **Descriptor:** The filter matches the `x-user-id` header to create a unique descriptor key (`user`).
*   **Why Excellent:** This goes beyond simple global IP limiting by enforcing quotas at the user identity level (e.g., 10 req/min per user), preventing a single user from degrading service for others.

---

## 6. Additional Istio Use Case: Shadow Launch (Model)

The deployment implements a **shadow launch** pattern for the `model-service`.

### Shadow Launch Architecture
*   **User-Visible Traffic**: All model responses for v1 users are served by **subset `primary`** (`model-v1`).
*   **Mirrored Traffic**: Istio's `mirror` feature copies 100% of these requests to **subset `shadow`** (`model-v2` or a dedicated shadow deployment).
*   **Outcome**:
    *   The `shadow` version processes the request asynchronously.
    *   Its response is **discarded** by the proxy and never returned to the user.
    *   This allows us to evaluate the performance and correctness of a new model version under real production traffic load without risking any negative impact on the user.

#### Shadow Launch Diagram

```mermaid
flowchart TB
    Source[App Service] --> TrafficSplit{VirtualService}
    
    TrafficSplit -->|100%| Primary[Model v1]
    TrafficSplit -.->|Mirror 100%| Shadow[Model v2]
    
    Primary -->|Response| User([Return to User])
    Shadow -->|Response| Void([Discard])
    
    style Source fill:#e1bee7
    style Primary fill:#c8e6c9
    style Shadow fill:#cfd8dc
    style Void fill:#ffcdd2
```

---

## 7. External Access

The application is exposed externally as follows:

*   **Hostname:** `sms-checker.local` (or `*`).
*   **Ports:** HTTP **80** (exposed via Istio IngressGateway).
*   **Paths:**
    *   `/`: Frontend web application.
    *   `/predict`: Prediction endpoint.
    *   `/metrics`: Prometheus metrics.
*   **Headers:** `x-user-id` (used for deterministic routing).

---

## 8. Observability

*   **Prometheus**: Scrapes metrics from `/metrics`. Discovered via `ServiceMonitor`.
    *   *Rules*: Includes `HighRequestRate` alerts.
*   **Grafana**: Pre-configured dashboards (loaded via ConfigMap) visualize:
    *   Request Rates (Golden Signals).
    *   v1 vs v2 Business Metrics (Conversion Rate).
*   **Alertmanager**: configured to route alerts (e.g., to email or webhook).

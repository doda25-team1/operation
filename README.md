# SMS Spam Checker

This repository contains the deployment files for the SMS Spam Checker application.

## Architecture Overview

The SMS Spam Checker consists of two main services and a shared library:

- [**app-service** ](../app): Spring Boot frontend application that serves the web UI and acts as an API gateway.
- [**model-service**](../model_service): Python Flask backend that provides ML-based spam detection.
- [**lib-version**](../lib-version): Shared Java library that exposes the packaged version at runtime (used by the app-service).

## Requirements

Before running the application, make sure to have the following installed:

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

### Setup (Locally)

1. **Setup .env using .env.example**
2. **Train the model** (required)
3. **Build the images** locally (optional)
4. **Start the services**

#### Step 1: Setup .env
Copy the `.env.example` file and change its name to `.env`. You can adjust configurations as you see fit.

#### Step 2: Train the Model (Required)

Follow the steps described in the `../model_service/README.md`. This is the model which will be used when you run docker-compose.
You will need to have both repositories setup.

#### Step 3: Build Images (Optional)
You can build the images on your own using these commands:

```bash
cd ../app
docker build -t ghcr.io/doda25-team1/app:latest .

cd ../model_service
docker build -t ghcr.io/doda25-team1/model-service:latest .
```

#### Step 4: Start Services
If you want to pull our images, use this:
```bash
cd ../operation
docker-compose up --pull always -d
```

Otherwise:
```bash
cd ../operation
docker-compose up -d
```

## Further Actions

### Visit the application website

Click `http://localhost:8080/sms/`.

### Stop the application

```bash
docker-compose down
```

### Verify Services are Running

```bash
docker-compose ps
```

### Modify Port Configuration

Modify `.env`:
```env
FRONTEND_HOST_PORT=3000
```

Restart services:
```bash
docker-compose down
docker-compose up -d
```

Visit `http://localhost:3000/sms/`.

## Building and Releasing

### Releasing to GitHub Container Registry

To release images to the GitHub Container Registry (required for the docker-compose to pull images):

1. **Authenticate with GitHub Container Registry:**
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

2. **Build and push frontend image:**
```bash
cd ../app
docker build -t ghcr.io/doda25-team1/app:latest .
docker push ghcr.io/doda25-team1/app:latest
```

3. **Build and push backend image:**
```bash
cd ../model_service
docker build -t ghcr.io/doda25-team1/model-service:latest .
docker push ghcr.io/doda25-team1/model-service:latest
```

## Debugging

### Service logs

```bash
docker-compose logs app-service
docker-compose logs model-service
```

### Restart services

```bash
docker-compose restart
```

## Use Kubernetes

This repo contains logic to set up a small Kubernetes cluster using Vagrant and Ansible.

### Prerequisites

- *VirtualBox*
- *Vagrant*
- *kubectl* (on your host machine)

### Provision the Kubernetes cluster

```bash
    cd ../operation
    vagrant up
```

### Use `kubectl` inside the controller VM

SSH into the controller:

```bash
    vagrant ssh ctrl
```

Inside the VM, `kubectl` is already configured for the `vagrant` user:

```bash
    # Show nodes
    kubectl get nodes
    
    # Show all pods in all namespaces
    kubectl get pods -A
```

> The kubeconfig used here is `/home/vagrant/.kube/config`.

### Use `kubectl` from the host machine

The provisioning also copies the kubeconfig to the host directory where you run Vagrant: `operation/.kube/config`.

This kubeconfig contains admin credentials and points to the correct API server.

#### Linux / macOS (bash/zsh):

```bash
    cd path/to/operation
    export KUBECONFIG="$(pwd)/.kube/config"

    kubectl get nodes
    kubectl get pods -A
```

#### Windows (PowerShell):

```bash
    cd C:\path\to\opeartion

    kubectl --kubeconfig "./.kube/config" get nodes
    kubectl --kubeconfig "./.kube/config" get pods -A
```

> If this does not work, copy the config to the default location kubectl expects (e.g. `c:\Users\username\.kube\config`) and run kubectl normally.
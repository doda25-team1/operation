# SMS Spam Checker

This repository contains the deployment files for the SMS Spam Checker application.

## Architecture Overview

The SMS Spam Checker consists of two main services:

- **app-service**: Spring Boot frontend application that serves the web UI and acts as an API gateway
- **model-service**: Python Flask backend that provides ML-based spam detection

## Requirements

Before running the application, make sure to have the following installed:

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

### Setup (Locally)

1. **Train the model**
2. **Build the images** locally
3. **Start the services**

#### Step 1: Train the Model

Follow the steps described in the `../model_service/README.md`. 

#### Step 2: Build Images

```bash
cd ../app
docker build -t ghcr.io/doda25-team1/app:latest .

cd ../model_service
docker build -t ghcr.io/doda25-team1/model-service:latest .
```

#### Step 3: Start Services

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
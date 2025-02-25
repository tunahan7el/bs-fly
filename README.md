# Backstage Deployment Solution

This repository contains an automated deployment solution for [Backstage](https://github.com/backstage/backstage) instances, focusing on reliability and graceful error handling.

## Solution Overview

Our deployment solution uses Kind (Kubernetes in Docker) to provide a consistent environment for both development and production-like deployments. This approach ensures that you can test the entire deployment process locally before moving to a real production environment.

## Why These Tools?

1. **Kind (Kubernetes in Docker)**
   - Runs Kubernetes clusters locally inside Docker containers
   - Perfect for testing and development
   - Matches production Kubernetes behavior
   - Enables testing of full deployment workflows

2. **Kubernetes**
   - Provides production-grade container orchestration
   - Supports zero-downtime deployments with rolling updates
   - Offers robust health checking and auto-healing
   - Enables horizontal scaling and load balancing
   - Provides built-in secrets and configuration management

3. **Kustomize**
   - Manages environment-specific configurations
   - Enables configuration reuse across environments
   - Simplifies configuration management
   - Native Kubernetes support

4. **Nginx Ingress Controller**
   - Provides advanced routing capabilities
   - Handles SSL/TLS termination
   - Enables host-based routing
   - Supports path-based routing and rewriting

## Prerequisites

- Docker installed
- Kind installed (`brew install kind` on macOS)
- kubectl installed
- Git installed

## Setup and Deployment

1. Create the Kind cluster with Ingress support:
   ```bash
   kind create cluster --config kind-config.yaml
   ```

2. Install the Nginx Ingress Controller:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   ```

3. Wait for the Ingress Controller to be ready:
   ```bash
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=90s
   ```

4. Deploy the application:
   ```bash
   # For development environment
   ./scripts/k8s-deploy.sh dev

   # For production-like environment
   ./scripts/k8s-deploy.sh prod
   ```

   Note: The script will automatically apply the ingress configuration. If you need to apply it manually:
   ```bash
   kubectl apply -f config/base/ingress.yaml
   ```

5. Add local DNS entry (if not already added by the script):
   ```bash
   echo "127.0.0.1 backstage.local" | sudo tee -a /etc/hosts
   ```

6. Access Backstage at `http://backstage.local`

## Configuration Management

The configuration is managed using Kustomize and organized as follows:

```
config/
├── base/               # Base configurations
│   ├── kustomization.yaml
│   ├── backstage.yaml
│   ├── postgres.yaml
│   ├── ingress.yaml    # Ingress configuration (applied separately)
│   └── backstage-config.yaml
├── dev/               # Development environment
│   └── kustomization.yaml
└── prod/              # Production environment
    └── kustomization.yaml
```

Key differences between environments:
- **Dev**: Single replica, lower resource limits
- **Prod**: Multiple replicas, higher resource limits, additional monitoring

## Deployment Features

1. **High Availability**
   - Multiple replicas in production
   - Rolling updates for zero-downtime deployments
   - Automatic health checks and recovery

2. **Data Persistence**
   - PostgreSQL StatefulSet
   - Persistent Volume Claims
   - Data survives pod restarts

3. **Security**
   - Secrets management
   - Resource isolation
   - Network policies (configurable)

4. **Monitoring**
   - Readiness probes
   - Liveness probes
   - Resource monitoring

5. **Ingress Configuration**
   - Host-based routing (`backstage.local`)
   - Path-based routing
   - Health check endpoint at `/health`
   - Support for SSL/TLS (configurable)

## Common Commands

```bash
# Deploy to development
./scripts/k8s-deploy.sh dev

# Deploy to production-like environment
./scripts/k8s-deploy.sh prod

# View all resources
kubectl get all

# View logs
kubectl logs -f deployment/backstage
kubectl logs -f statefulset/postgres

# Check Ingress status
kubectl get ingress
kubectl describe ingress backstage-ingress

# Scale replicas
kubectl scale deployment backstage --replicas=3

# Delete cluster
kind delete cluster --name backstage-cluster

# Manually apply ingress (if needed)
kubectl apply -f config/base/ingress.yaml
```

## Error Handling and Recovery

1. **Pre-deployment Checks**
   - Tool availability verification
   - Cluster health checks
   - Resource validation

2. **Deployment Safety**
   - Rolling updates
   - Health monitoring
   - Automatic rollbacks

3. **State Preservation**
   - Persistent volumes
   - Backup capabilities
   - State recovery procedures

## Troubleshooting

Common issues and their solutions:

1. **Cluster Creation Fails**
   - Ensure Docker is running
   - Check available system resources
   - Verify Kind installation

2. **Image Pull Fails**
   - Images are pre-loaded into Kind cluster
   - Check Docker image build logs
   - Verify local image exists

3. **Service Unavailable**
   - Check pod status: `kubectl get pods`
   - View logs: `kubectl logs -f deployment/backstage`
   - Check Ingress status: `kubectl get ingress`
   - Verify DNS entry in `/etc/hosts`

4. **Ingress Issues**
   - Verify Ingress Controller is running: `kubectl get pods -n ingress-nginx`
   - Check Ingress configuration: `kubectl describe ingress backstage-ingress`
   - Ensure ports 80/443 are available on your host
   - Check Ingress Controller logs: `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller`
   - If ingress is not working, try applying it manually: `kubectl apply -f config/base/ingress.yaml`


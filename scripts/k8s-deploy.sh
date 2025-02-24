#!/bin/bash

set -e

echo "🚀 Starting Kubernetes deployment..."

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install $1 first."
        exit 1
    fi
}

check_tool docker
check_tool kind
check_tool kubectl
check_tool kustomize

# Set environment (default to dev if not specified)
ENV=${1:-dev}
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "❌ Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

echo "🌍 Deploying to $ENV environment..."

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "^backstage-cluster$"; then
    echo "🏗️ Creating Kind cluster..."
    kind create cluster --config kind-config.yaml
else
    echo "✅ Using existing Kind cluster"
fi

# Set kubectl context to Kind cluster
kubectl cluster-info --context kind-backstage-cluster

# Build Docker image
echo "🏗️ Building Docker image..."
docker build -t backstage:latest .

# Load the image into Kind cluster
echo "📦 Loading image into Kind cluster..."
kind load docker-image backstage:latest --name backstage-cluster

# Apply Kustomize configurations
echo "🔧 Applying Kubernetes configurations for $ENV environment..."
kubectl apply -k config/$ENV

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

echo "⏳ Waiting for Backstage deployment to be ready..."
kubectl wait --for=condition=available deployment/backstage --timeout=300s

# Get service URL
echo "🔍 Getting service URL..."
echo "✅ Backstage is accessible at http://localhost:8080"

echo "✨ Deployment completed successfully!"
echo "📊 To view logs: kubectl logs -f deployment/backstage"
echo "🔄 To restart: kubectl rollout restart deployment/backstage"
echo "🗑️ To delete cluster: kind delete cluster --name backstage-cluster"

# Print additional commands
echo -e "\n📝 Useful commands:"
echo "- View all resources: kubectl get all"
echo "- View Backstage logs: kubectl logs -f deployment/backstage"
echo "- View PostgreSQL logs: kubectl logs -f statefulset/postgres"
echo "- Scale replicas: kubectl scale deployment backstage --replicas=<number>"
echo "- Switch environment: ./scripts/k8s-deploy.sh [dev|prod]" 
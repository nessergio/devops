# Application Layer

**IMPORTANT:** This folder contains template files that are pushed to Azure DevOps during bootstrap. After bootstrap completes, clone the application repository from Azure DevOps and work with that cloned copy instead. Do NOT use this local folder for ongoing development.

Sample web application with Docker image build pipeline. Deployment is handled by ArgoCD (GitOps).

## Contents

- **Dockerfile** - Container image definition (Nginx-based)
- **index.html** - Static web content
- **pipelines/** - Azure DevOps CI/CD pipeline (builds and pushes Docker images)

## Application Stack

- **Base Image:** Nginx
- **Content:** Static HTML
- **Port:** 80

## Deployment - GitOps Workflow

**After Bootstrap:** Clone the application and charts repositories from Azure DevOps:
```bash
cd ~/workspace
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/<ProjectName>
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Charts
```

### GitOps Deployment Flow

1. **Developer pushes code** to the App repository
2. **App Deploy pipeline** automatically builds and pushes Docker image to ACR
3. **ArgoCD Image Updater** detects new image in ACR
4. **ArgoCD** automatically updates the deployment in AKS
5. **No manual kubectl commands needed**

### Making Changes

```bash
cd <ProjectName>

# Edit application files
vim index.html

# Commit and push
git add .
git commit -m "Update application"
git push

# Pipeline builds image, ArgoCD deploys automatically
# Monitor deployment in ArgoCD UI at https://<your-fqdn>/argocd
```

### Manual Image Build (Optional)

```bash
ACR_NAME=<your-acr-name>  # Get from Infrastructure repository outputs
az acr login --name $ACR_NAME
docker build -t $ACR_NAME.azurecr.io/hello-test:v1 .
docker push $ACR_NAME.azurecr.io/hello-test:v1

# ArgoCD Image Updater will detect and deploy the new image automatically
```

## Directory Structure

```
app/
├── Dockerfile              # Container image definition
├── index.html             # Static web content
├── .dockerignore          # Docker build exclusions
└── pipelines/
    └── azure-pipelines.yaml  # Docker image build pipeline
```

## Kubernetes Resources

Kubernetes resources are defined as Helm charts in the separate Charts repository:

```
charts/test/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml    # Kubernetes deployment
    ├── service.yaml       # ClusterIP service (port 80)
    ├── ingress.yaml       # Ingress routing with TLS
    └── hpa.yaml          # Horizontal Pod Autoscaler
```

These are deployed automatically by ArgoCD.

## CI/CD Pipeline

**Trigger:** Git push to master branch

**Stages:**
1. Build Docker image
2. Tag with build ID and 'latest'
3. Push to ACR

**Deployment:** Handled automatically by ArgoCD Image Updater

## Prerequisites

- Infrastructure layer deployed (ACR, AKS, and ArgoCD available)
- Charts repository initialized with Helm charts

---

© 2025 Serhii Nesterenko

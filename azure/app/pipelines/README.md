# Application CI/CD Pipeline

Azure DevOps pipeline for building and deploying the sample application to AKS.

## Pipeline: azure-pipelines.yaml

Builds Docker image, pushes to ACR, and deploys to AKS cluster.

## Stages

### 1. Build
- Builds Docker image from Dockerfile
- Tags image with build ID
- Pushes image to Azure Container Registry

### 2. Deploy
- Connects to AKS cluster
- Updates deployment with new image tag
- Applies Kubernetes manifests

## Trigger

**Build Completion Trigger:** Automatically runs after "Infrastructure Deploy" pipeline completes successfully.

Can also be triggered manually from Azure DevOps.

## Variables

Uses Variable Group created by infrastructure layer:
- `AKS_CLUSTER_NAME` - AKS cluster name
- `AKS_RESOURCE_GROUP` - Resource group containing AKS
- `ACR_NAME` - Container registry name
- `ACR_LOGIN_SERVER` - ACR login server URL

## Service Connection

Uses Azure service connection created by bootstrap layer for authentication.

## Agent

Runs on self-hosted agent (Default pool) with Docker installed.

## Manual Run

1. Navigate to Azure DevOps → Pipelines → "App Deploy"
2. Click "Run pipeline"
3. Select branch (default: master)
4. Click "Run"

## Notes

- Pipeline fails if infrastructure layer not deployed
- Requires AKS cluster and ACR to be available
- Image tag is based on pipeline build number
- Deployment uses rolling update strategy

---

© 2025 Serhii Nesterenko

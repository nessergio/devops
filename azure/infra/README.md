# Infrastructure Layer

**IMPORTANT:** This folder contains template files that are pushed to Azure DevOps during bootstrap. After bootstrap completes, clone the Infrastructure repository from Azure DevOps and work with that cloned copy instead. Do NOT use this local folder for ongoing development.

Deploys Azure Kubernetes Service (AKS) cluster with container registry and ingress.

## What This Creates

- **Azure Container Registry (ACR)** - Private Docker image registry
- **AKS Cluster** - Kubernetes cluster with autoscaling node pool (1-3 nodes)
- **Static Public IP** - For ingress controller
- **NGINX Ingress Controller** - HTTP/HTTPS traffic routing (Helm chart)
- **Cert-Manager** - Automatic SSL/TLS certificates from Let's Encrypt (Helm chart)
- **Service Connection** - Azure DevOps connection for app deployment
- **Variable Group** - Pipeline variables for app deployment

## Usage

**After Bootstrap:** Clone the Infrastructure repository from Azure DevOps to work with it:
```bash
cd ~/workspace
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
cd Infrastructure
```

### Option 1: Azure DevOps Pipeline (Recommended)
Run the "Infrastructure Deploy" pipeline from Azure DevOps web UI.

### Option 2: Manual Terraform (from cloned repository)
```bash
# Configure settings
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with ACR name and AKS settings

# Deploy
terraform init
terraform apply

# Connect to cluster
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)
```

## Key Files

- `1_acr.tf` - Azure Container Registry
- `1_aks.tf` - AKS cluster with autoscaling node pool
- `1_pip.tf` - Static public IP for ingress
- `2_ingress.tf` - NGINX ingress controller (Helm)
- `2_certmanager.tf` - Cert-manager for SSL/TLS (Helm)
- `2_service_connections.tf` - Azure DevOps service connection
- `3_variable_group.tf` - Variable group for app pipeline
- `pipelines/deploy.yml` - Infrastructure deployment pipeline
- `pipelines/destroy.yml` - Infrastructure destruction pipeline

## Outputs

- `acr_name` - Container registry name
- `acr_login_server` - ACR login server URL
- `aks_cluster_name` - AKS cluster name
- `ingress_public_ip` - Public IP for ingress

## State Management

Uses **remote state** in Azure Blob Storage created by bootstrap layer.

## Prerequisites

- Bootstrap layer must be deployed first
- Build agent VM must be online

---

© 2025 Serhii Nesterenko

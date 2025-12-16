# Setup Guide

Complete step-by-step guide for setting up the Azure infrastructure automation project.

## Prerequisites

### Azure Requirements
- Active Azure subscription with Contributor role
- Azure CLI installed and configured
- Sufficient quota for VMs, Storage, ACR, and AKS

### Azure DevOps Requirements
- Azure DevOps organization
- Personal Access Token (PAT) with scopes:
  - Agent Pools: Read & Manage
  - Build: Read & Execute
  - Code: Read, Write, & Manage
  - Project and Team: Read, Write, & Manage
  - Service Connections: Read, Query, & Manage
  - Variable Groups: Read, Create, & Manage

### Local Requirements
- Terraform >= 1.14
- kubectl
- Docker (optional)
- Git
- SSH client

## Step 1: Azure Authentication

```bash
# Login to Azure
az login

# Verify subscription
az account show

# Set subscription if needed
az account set --subscription "Your-Subscription-Name"
```

## Step 2: Create Azure DevOps PAT

1. Navigate to Azure DevOps → User Settings → Personal Access Tokens
2. Click "New Token"
3. Configure:
   - Name: "Terraform Infrastructure"
   - Organization: Select your organization
   - Expiration: 90 days (or as per policy)
   - Scopes: Select all required scopes listed above
4. Click "Create" and **copy the token immediately**

## Step 3: Bootstrap Layer Deployment

```bash
# Navigate to bootstrap directory
cd bootstrap

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars  # or use your preferred editor
```

Configure the following variables:
```hcl
azure_devops_pat         = "your-pat-token-here"
azure_devops_org_url     = "https://dev.azure.com/your-org"
azure_devops_project     = "Infrastructure"
location                 = "eastus"
resource_group_name      = "rg-bootstrap"
storage_account_prefix   = "tfstate"
agent_vm_name            = "vm-build-agent"
agent_vm_size            = "Standard_B2s"
agent_vm_admin_username  = "azureuser"
```

Deploy bootstrap:
```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply configuration
terraform apply

# Save important outputs
terraform output > bootstrap-outputs.txt
```

**Expected Duration:** 10-15 minutes

## Step 4: Verify Bootstrap Deployment

```bash
# Check build agent VM
terraform output build_agent_public_ip

# SSH to build agent
ssh -i agent_ssh_key.pem azureuser@$(terraform output -raw build_agent_public_ip)

# On build agent, verify agent service
cd ~/agent
sudo ./svc.sh status
exit

# Open Azure DevOps project
terraform output project_url
```

Verify in Azure DevOps:
- Project created
- Three repositories (Infrastructure, App, Charts)
- Three pipelines created
- Agent visible in Agent Pools → Default

## Step 5: Clone Infrastructure Repository from Azure DevOps

**IMPORTANT:** Do NOT use the local `infra/` folder after bootstrap. Clone the Infrastructure repository from Azure DevOps instead.

```bash
# Navigate to a workspace directory (outside this project)
cd ~/workspace  # or any directory of your choice

# Clone Infrastructure repository from Azure DevOps
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
cd Infrastructure

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

Configure the following variables:
```hcl
azure_devops_pat     = "your-pat-token-here"  # Same as bootstrap
azure_devops_org_url = "https://dev.azure.com/your-org"
azure_devops_project = "Infrastructure"
resource_group_name  = "rg-aks-infrastructure"
location             = "East US"
acr_name             = "myuniqueacr123"  # Must be globally unique
aks_cluster_name     = "aks-cluster"
aks_dns_prefix       = "myaks"
system_node_count    = 1
system_node_min_count = 1
system_node_max_count = 3
system_node_vm_size  = "Standard_DS2_v2"
```

## Step 6: Infrastructure Layer Deployment

### Option A: Azure DevOps Pipeline (Recommended)

1. Open Azure DevOps project
2. Navigate to Pipelines
3. Select "Infrastructure Deploy"
4. Click "Run pipeline"
5. Review and approve plan
6. Wait for completion (~15-20 minutes)

### Option B: Manual Terraform Deployment

```bash
# From the cloned Infrastructure repository
terraform init

# Review plan
terraform plan

# Apply configuration
terraform apply

# Save outputs
terraform output > infra-outputs.txt
```

**Expected Duration:** 15-20 minutes

## Step 7: Verify Infrastructure Deployment

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify cluster connectivity
kubectl get nodes
kubectl get namespaces

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check cert-manager
kubectl get pods -n cert-manager

# Check ArgoCD and Image Updater
kubectl get pods -n argocd
kubectl get secret acr-credentials -n argocd  # ACR token secret

# Verify ACR
az acr login --name $(terraform output -raw acr_name)

# Verify ACR token (optional)
az acr token show --name image-updater-token --registry $(terraform output -raw acr_name)
```

## Step 8: Application Deployment

The application deploys automatically via pipeline after infrastructure deployment completes.

### Option A: Automatic Pipeline Deployment (Recommended)
Wait for the "App Deploy" pipeline to trigger automatically after "Infrastructure Deploy" completes.

### Option B: Manual Deployment from Cloned Repository

**IMPORTANT:** Do NOT use the local `app/` folder after bootstrap. Clone the application repository from Azure DevOps instead.

```bash
# Navigate to workspace directory (outside this project)
cd ~/workspace  # or any directory of your choice

# Clone application and charts repositories from Azure DevOps
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/<ProjectName>
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Charts

# Application deployments are handled automatically by ArgoCD
# The infrastructure deployment already installed ArgoCD and bootstrapped the application

# To trigger a new deployment, simply push code changes to the App repository
cd <ProjectName>
# Make changes to index.html or Dockerfile
git add .
git commit -m "Update application"
git push

# The App Deploy pipeline will build and push the Docker image
# ArgoCD Image Updater will detect the new image and update the deployment automatically

# Check deployment status via kubectl
kubectl get pods -n default
kubectl get applications -n argocd
kubectl describe application test -n argocd

# Or access ArgoCD UI
echo "Access ArgoCD at: https://$(cd ~/workspace/Infrastructure && terraform output -raw ingress_fqdn)/argocd"
```

## Step 9: Access Application

```bash
# Get application URL from Terraform output in cloned Infrastructure repository
cd ~/workspace/Infrastructure  # or wherever you cloned it
terraform output ingress_url

# Also get the FQDN
terraform output ingress_fqdn
```

Access application at the HTTPS URL shown in the output: `https://<FQDN>/`

The application is automatically configured with a Let's Encrypt SSL certificate and is accessible via HTTPS.

## Common Issues

### Issue: PAT Authentication Fails
**Solution:** Verify PAT has all required scopes and hasn't expired.

### Issue: ACR Name Not Unique
**Solution:** Choose a different name (alphanumeric only, globally unique).

### Issue: Build Agent Not Online
**Solution:** SSH to VM and check agent service status.

### Issue: AKS Deployment Fails - Quota Exceeded
**Solution:** Request quota increase in Azure portal or use smaller VM size.

### Issue: Terraform State Locked
**Solution:** Wait for operations to complete or break lease in Azure portal.

### Issue: ArgoCD Image Updater Cannot Authenticate to ACR
**Symptoms:**
- Error: "unauthorized: authentication required" in Image Updater logs
- Images not updating automatically

**Solution:**
1. Verify ACR token secret exists:
   ```bash
   kubectl get secret acr-credentials -n argocd
   ```
2. Check Image Updater logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```
3. Verify token hasn't expired (1-year default):
   ```bash
   az acr token show --name image-updater-token --registry <acr-name> --query "credentials.passwords[0].expiry"
   ```
4. If expired, re-run `terraform apply` to regenerate the token

### Issue: ACR Token Expiry
**Prevention:**
- ACR tokens expire after 1 year by default
- Set up monitoring or calendar reminders for token rotation
- Re-run `terraform apply` in infrastructure layer to regenerate tokens before expiry

## Next Steps

- Configure DNS for ingress public IP
- Set up monitoring and logging
- Configure backup policies
- Review security settings
- Set up additional environments (staging, production)

## Cleanup

To remove all resources:

```bash
# Destroy infrastructure (from cloned Infrastructure repository)
cd ~/workspace/Infrastructure
terraform destroy -auto-approve

# Destroy bootstrap (from original bootstrap project)
cd /path/to/original/project/bootstrap
terraform destroy -auto-approve
```

**Warning:** This will delete all resources including Azure DevOps project and state storage.

---

© 2025 Serhii Nesterenko

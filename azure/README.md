# Azure Infrastructure as Code with CI/CD

Terraform infrastructure automation for Azure with integrated Azure DevOps CI/CD pipelines and self-hosted build agent.

## Prerequisites

Before you begin, ensure you have the following:

- **Azure Subscription** - Active Azure subscription with sufficient permissions to create resources
- **Azure DevOps Organization** - Organization URL (e.g., `https://dev.azure.com/<org-name>`)
- **Azure DevOps PAT** - Personal Access Token with required scopes:
  - Agent Pools: Read & Manage
  - Build: Read & Execute
  - Code: Read, Write, & Manage
  - Project and Team: Read, Write, & Manage
  - Service Connections: Read, Query, & Manage
  - Variable Groups: Read, Create, & Manage
- **Azure CLI** - [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform** - Version >= 1.14 ([Download](https://www.terraform.io/downloads))
- **kubectl** - Kubernetes command-line tool ([Install](https://kubernetes.io/docs/tasks/tools/))
- **Git** - Version control system
- **SSH client** - For accessing the build agent VM

## ⚠️ Important Workflow Notice

**This project bootstraps infrastructure and pushes code to Azure DevOps repositories.**

- The `infra/` and `app/` folders are **templates only** - they initialize Azure DevOps repositories during bootstrap
- **After bootstrap completes:** Clone repositories from Azure DevOps to separate folders
- **Do NOT use local `infra/` and `app/` folders** for ongoing development
- Use standard git workflow with cloned repositories from Azure DevOps

```bash
# Correct workflow after bootstrap:
cd ~/workspace
git clone https://<pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
git clone https://<pat>@dev.azure.com/<org>/<project>/_git/<ProjectName>
```

## Project Overview

This is an enterprise-grade Terraform-based infrastructure automation project for Azure that implements GitOps with ArgoCD and a three-layer architecture:

1. **Bootstrap Layer** (`bootstrap/` directory) - Creates foundational infrastructure, CI/CD environment, and self-hosted build agent
2. **Infrastructure Layer** (`infra/` directory) - Template for Infrastructure repository in Azure DevOps, deploys ArgoCD and AKS
3. **Application Layer** (`app/` directory) - Template for application repository containing Docker image build pipeline
4. **Charts Layer** (Azure DevOps repository) - Helm charts for GitOps-based deployments via ArgoCD

The bootstrap process creates state storage, Azure DevOps project with three Git repositories (Infrastructure, App, Charts), self-hosted build agent VM, three pipelines, and automatically pushes code to Azure DevOps repositories. Infrastructure deployment installs ArgoCD, ArgoCD Image Updater, and bootstraps GitOps continuous deployment.

## High-Level Architecture

### Bootstrap → Infra → App Flow

The bootstrap layer must run first as it:
1. Creates Azure Storage Account and Blob Container for remote Terraform state
2. Creates Azure DevOps Project with three Git repositories:
   - **Infrastructure** - Contains infrastructure Terraform code and pipelines
   - **App** - Contains application code, Dockerfile, and build pipeline
   - **Charts** - Contains Helm charts for ArgoCD deployments
3. Creates self-hosted build agent VM (Ubuntu 22.04) with Docker and Azure Pipelines agent
4. Creates Service Principal and Azure DevOps Service Connection for pipeline authentication
5. Creates three Azure DevOps pipelines:
   - **Infrastructure Deploy** - Deploys infrastructure layer (AKS, ACR, ArgoCD)
   - **Infrastructure Destroy** - Destroys infrastructure layer
   - **App Deploy** - Builds and pushes Docker images to ACR
6. Uses reusable DevOps project module to initialize repositories with code
7. Automatically pushes code to respective Azure DevOps repositories

### State Management Pattern

- **Bootstrap**: Uses local state (no backend configured) - this is intentional as it creates the state storage
- **Infra**: Uses remote state in Azure Blob Storage
  - Backend configuration is NOT auto-generated
  - State key: `${var.azure_devops_project}.tfstate`
  - Backend details passed as pipeline variables
- **App**: No Terraform state (builds Docker images only)
- **Charts**: No Terraform state (Helm charts managed by ArgoCD)

### Azure DevOps Integration

The project creates a complete CI/CD environment with GitOps:
- **Build Agent VM**: Self-hosted agent with Docker, eliminates dependency on Microsoft-hosted agents
- **Service Principal**: Contributor role on subscription, 2-year credential expiration
- **Service Connection**: Authorizes pipelines to deploy Azure resources
- **Variable Groups**: Store configuration for pipeline reuse
- **Three Git Repositories**:
  - "Infrastructure" - Contains infra Terraform code and pipelines
  - "<Project Name>" - Contains application code and Dockerfile (default: "TestProject")
  - "Charts" - Contains Helm charts for ArgoCD GitOps deployments
- **Three Pipelines**:
  - Infrastructure Deploy (`pipelines/deploy.yml`) - Deploys AKS, ACR, ArgoCD, and bootstraps GitOps
  - Infrastructure Destroy (`pipelines/destroy.yml`) - Destroys infrastructure
  - App Deploy (`pipelines/azure-pipelines.yaml`) - Builds and pushes Docker images to ACR
- **GitOps Workflow**: ArgoCD Image Updater automatically detects new images in ACR and updates deployments

## Common Commands

### Bootstrap Workflow

```bash
# From bootstrap/ directory
terraform init
terraform plan
terraform apply

# View outputs (storage account, Azure DevOps URLs, build agent details, etc.)
terraform output

# Access build agent VM
ssh -i agent_ssh_key.pem azureuser@$(terraform output -raw build_agent_public_ip)

# Check agent status on VM
cd ~/agent
sudo ./svc.sh status
```

### Infrastructure Workflow

**IMPORTANT:** After bootstrap completes, clone the Infrastructure repository from Azure DevOps to a separate folder and work with it using standard git flow. Do NOT use the local `infra/` folder in this project after bootstrap - it serves only as a template for repository initialization.

```bash
# Clone Infrastructure repository from Azure DevOps
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
cd Infrastructure

# Work with the cloned repository
# Make changes, commit, and push using standard git workflow

# View ACR, AKS, and ingress details
terraform output

# Connect to AKS cluster
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) --overwrite-existing

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### Application Workflow - GitOps with ArgoCD

**IMPORTANT:** After bootstrap completes, clone both the application and charts repositories from Azure DevOps:

```bash
# Clone application repository (builds Docker images)
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/<ProjectName>

# Clone charts repository (Helm charts for ArgoCD)
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Charts
```

#### GitOps Deployment Flow

The project uses ArgoCD for GitOps-based continuous deployment:

1. **Developer pushes code** to the App repository
2. **App pipeline triggers** automatically:
   - Builds Docker image
   - Tags with build ID and `latest`
   - Pushes to Azure Container Registry (ACR)
3. **ArgoCD Image Updater detects** new image in ACR
4. **ArgoCD automatically updates** the deployment in AKS
5. **ArgoCD syncs** the Helm chart from Charts repository

#### ArgoCD Architecture

- **ArgoCD Server**: Web UI accessible at `https://<your-fqdn>/argocd`
  - Default admin credentials configured via Terraform
  - Manages GitOps deployments
- **ArgoCD Image Updater**: Watches ACR for new images
  - Automatically updates image tags in deployments
  - Uses digest-based update strategy for reliability
- **Root Application** (App of Apps pattern):
  - Deployed via Terraform during infrastructure deployment
  - Points to `charts/root/` in Charts repository
  - Manages child applications (e.g., `test` application)
- **Child Applications**:
  - Defined as ArgoCD Application resources
  - Each points to a Helm chart in Charts repository
  - Auto-sync enabled for continuous deployment

#### Charts Repository Structure

```
charts/
├── root/                          # Root application (App of Apps)
│   ├── Chart.yaml
│   ├── values.yaml               # Default values (ACR, hostname, etc.)
│   └── templates/
│       ├── test.yaml             # Test application ArgoCD resource
│       └── test-image-updater.yaml  # Image updater CRD for automatic updates
└── test/                         # Application Helm chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        └── hpa.yaml
```

#### Making Changes

**To update application code:**
```bash
cd <ProjectName>
# Make changes to index.html or Dockerfile
git add .
git commit -m "Update application"
git push
# Pipeline builds and pushes new image, ArgoCD Image Updater deploys automatically
```

**To update Helm chart configuration:**
```bash
cd Charts
# Edit charts/test/values.yaml or templates
git add .
git commit -m "Update configuration"
git push
# ArgoCD detects changes and syncs automatically
```

### Git Authentication for Azure DevOps

The DevOps project module handles git authentication internally using the PAT token.
Repository initialization happens automatically during bootstrap terraform apply.

## Required Credentials

### Bootstrap requires (via terraform.tfvars):
- `azure_devops_pat` - Personal Access Token with scopes:
  - Agent Pools: Read & Manage
  - Build: Read & Execute
  - Code: Read, Write, & Manage
  - Project and Team: Read, Write, & Manage
  - Service Connections: Read, Query, & Manage
  - Variable Groups: Read, Create, & Manage
- `azure_devops_org_url` - e.g., `https://dev.azure.com/<org-name>`
- `azure_devops_project` - Project name (default: "TestProject")
- Additional variables for build agent VM configuration (see terraform.tfvars.example)

### Infrastructure requires (via terraform.tfvars):
- `acr_name` - Globally unique ACR name (alphanumeric only)
- AKS cluster configuration variables
- Azure resource configuration

### Azure authentication:
```bash
az login  # Required before running any Terraform commands
```

## Key Files and Their Relationships

### Bootstrap Layer

#### Core Infrastructure Files (numbered for load order):
- `0_provider.tf` - Azure and Azure DevOps provider configuration
- `0_variables.tf` - Input variable definitions
- `0_outputs.tf` - Output values (storage details, Azure DevOps URLs, build agent info, Service Principal)
- `0_azuredevops_extensions.tf` - Azure DevOps extensions installation
- `1_storage.tf` - Azure Storage Account with random suffix and blob container for Terraform state
- `1_build_agent.tf` - Ubuntu VM with Docker and Azure Pipelines agent installation
- `2_project.tf` - Azure DevOps project, three Git repositories (Infrastructure, App, Charts), three pipelines using devops_project module
- `2_service_connections.tf` - Service Principal and Azure DevOps Service Connection for pipeline authentication

#### Module: devops_project (bootstrap/modules/devops_project/)
- `1_main.tf` - Creates Azure DevOps project and initializes repositories with code
- `1_permissions.tf` - Configures Git repository permissions
- `0_provider.tf` / `0_variables.tf` / `0_outputs.tf` - Module configuration

#### Generated Files:
- `agent_ssh_key.pem` - Private SSH key for build agent VM access (not committed)
- `terraform.tfstate` - Local state for bootstrap resources (not committed)

### Infrastructure Layer

#### Core Infrastructure Files (numbered for load order):
- `0_provider.tf` - Azure, Kubernetes, Helm, and Azure DevOps providers
- `0_variables.tf` - Input variable definitions (includes `argocd_admin_pass`)
- `0_outputs.tf` - Output values (ACR, AKS, ingress details, ArgoCD URL)
- `1_acr.tf` - Azure Container Registry with ACR token for Image Updater authentication
- `1_aks.tf` - AKS cluster with autoscaling system node pool
- `1_pip.tf` - Public IP for ingress controller with FQDN
- `2_ingress.tf` - NGINX Ingress Controller deployed via Helm
- `2_certmanager.tf` - Cert-Manager for Let's Encrypt SSL certificates
- `2_argocd.tf` - ArgoCD, ArgoCD Apps (root application), ArgoCD Image Updater, and ACR credentials secret
- `2_service_connections.tf` - Azure DevOps Service Connection (references bootstrap)
- `3_variable_group.tf` - Azure DevOps Variable Group for pipeline configuration

#### Helper Scripts (infra/scripts/):
- `bcrypt-password.py` - Generates bcrypt hash for ArgoCD admin password
- `ssh-keyscan-json.sh` - Retrieves Azure DevOps SSH host keys for ArgoCD

#### Pipeline Files (infra/pipelines/):
- `deploy.yml` - Infrastructure deployment pipeline (Validate → Plan → Apply)
- `destroy.yml` - Infrastructure destruction pipeline

### Application Layer

#### Application Files (app/):
- `index.html` - Static web content
- `Dockerfile` - Container image definition
- `.dockerignore` - Files to exclude from Docker build

#### Pipeline Files (app/pipelines/):
- `azure-pipelines.yaml` - Docker image build pipeline (Build → Push to ACR)

### Charts Layer

#### Helm Charts (charts/):
- `root/` - Root ArgoCD application (App of Apps pattern)
  - `Chart.yaml` - Helm chart metadata
  - `values.yaml` - Configuration values (ACR, hostname, TLS secret name)
  - `templates/test.yaml` - Child application definition
  - `templates/test-image-updater.yaml` - ImageUpdateAutomation CRD for automatic updates
- `test/` - Application Helm chart
  - `Chart.yaml` - Chart metadata
  - `values.yaml` - Default values
  - `templates/` - Kubernetes manifests (deployment, service, ingress, HPA)
  - `README.md` - Chart documentation

## Important Patterns

### File Naming Convention
Files are prefixed with numbers to control load order:
- `0_*.tf` - Providers, variables, outputs (foundational)
- `1_*.tf` - Core infrastructure resources
- `2_*.tf` - Secondary resources that depend on core
- `3_*.tf` - Tertiary resources and integrations

### Service Principal and Service Connections
The Service Principal created in bootstrap (`azuread_application` and `azuread_service_principal`) is used by:
- **Azure-ServiceConnection**: Used by Infrastructure Deploy and Infrastructure Destroy pipelines

The infrastructure layer creates additional service connections:
- **acr-rbac-connection**: ACR service connection for Docker image operations
- **kubernetes-rbac-connection**: Kubernetes service connection for AKS deployments
- Both are used by the App Deploy pipeline

### Build Agent VM
- Self-hosted agent eliminates dependency on Microsoft-hosted agents
- Ubuntu 22.04 LTS with Docker pre-installed
- Azure Pipelines agent automatically configured and started as a service
- SSH access via generated key pair (agent_ssh_key.pem)
- Public IP for remote access (consider restricting via NSG rules)
- Checks for existing agent installation to prevent duplicate setup

### Dependency Chain
```
Bootstrap terraform apply
  ↓
Creates Storage Account & Resource Group
  ↓
Creates Build Agent VM with Azure Pipelines agent
  ↓
Creates Azure DevOps Project with three Git repos:
  - Infrastructure
  - <ProjectName> (app)
  - Charts
  ↓
Creates Service Principal & Azure DevOps Service Connection
  ↓
Creates three Azure DevOps Pipelines:
  - Infrastructure Deploy (deploy.yml)
  - Infrastructure Destroy (destroy.yml)
  - App Deploy (azure-pipelines.yaml)
  ↓
Module initializes repositories and pushes code:
  - infra/ → Infrastructure repository
  - app/ → <ProjectName> repository
  - charts/ → Charts repository
  ↓
Ready for deployment (run "Infrastructure Deploy" pipeline)
  ↓
Infrastructure layer deploys via Terraform:
  - ACR, AKS, Public IP with FQDN
  - NGINX Ingress Controller
  - Cert-Manager for TLS certificates
  - ArgoCD with web UI at /argocd
  - ArgoCD Image Updater (watches ACR)
  - Root ArgoCD Application (App of Apps)
  - Creates Variable Group for app pipeline
  ↓
ArgoCD bootstraps application deployment:
  - Root application deployed by Terraform
  - Root app creates child applications (e.g., test)
  - Child apps deploy Helm charts from Charts repo
  - Applications running in AKS
  ↓
GitOps Continuous Deployment:
  - Developer pushes code to App repo
  - App Deploy pipeline builds and pushes Docker image to ACR
  - ArgoCD Image Updater detects new image
  - ArgoCD automatically updates deployment
  - Application updated in AKS (zero manual intervention)
```

### Resource Naming
- Storage Account: `${var.storage_account_prefix}${random_string.storage_suffix.result}`
- Service Principal: `azdevops-${var.azure_devops_project}-service-connection`
- Azure Service Connection (Bootstrap): `Azure-ServiceConnection`
- ACR Service Connection (Infrastructure): `acr-rbac-connection`
- Kubernetes Service Connection (Infrastructure): `kubernetes-rbac-connection`
- Build Agent VM: `${var.agent_vm_name}` (default: "vm-build-agent")
- Pipelines: "Infrastructure Deploy", "Infrastructure Destroy", "App Deploy"

### Module Usage
The `devops_project` module is a reusable component that:
- Creates Azure DevOps project with specified features
- Initializes Git repositories with provided source code
- Commits and pushes code automatically using PAT authentication
- Configures repository permissions
- Returns project and repository IDs for pipeline configuration

## Working with Multiple Terraform Projects

The project has three independent layers:
- **Bootstrap**: Local state, manages foundational resources (storage, Azure DevOps, build agent)
- **Infrastructure**: Remote state in Azure Blob Storage, manages Azure resources (ACR, AKS, ingress)
- **Application**: No Terraform state, uses Kubernetes manifests and Docker

### Key Points:
- Always change directory to the appropriate project folder before running terraform commands
- Bootstrap must be applied before infrastructure
- Infrastructure creates resources that application deployment depends on
- All layers can reference the same Azure subscription but manage different resource types
- State locking prevents concurrent terraform operations on the same state file

## Troubleshooting

### Build Agent Not Connecting
SSH to the VM and check agent status:
```bash
cd bootstrap
ssh -i agent_ssh_key.pem azureuser@$(terraform output -raw build_agent_public_ip)
cd ~/agent
sudo ./svc.sh status
```
If the agent is not running, restart it:
```bash
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Backend Configuration in Pipelines
The infrastructure pipelines receive backend configuration via variables set in the pipeline definition:
- `TF_STATE_RESOURCE_GROUP`
- `TF_STATE_STORAGE_ACCOUNT`
- `TF_STATE_CONTAINER_NAME`
- `TF_STATE_KEY`

These are set automatically by the bootstrap layer when creating the pipelines.

### Repository Push Failures
The devops_project module handles repository initialization. If push fails:
- Verify PAT token has correct scopes (Code: Read, Write, & Manage)
- Check PAT token hasn't expired
- Enable `force_push = true` in bootstrap terraform.tfvars to overwrite existing repositories

### Service Connection Not Authorized
If pipelines fail with "Could not find a service connection with identifier":
- The bootstrap creates pipeline authorizations automatically for `Azure-ServiceConnection`
- The infrastructure layer creates `acr-rbac-connection` and `kubernetes-rbac-connection`
- If missing, re-run the respective layer or manually authorize in Azure DevOps UI
- Verify the service connection names match what's expected in the pipeline YAML files

### AKS Credentials Issues
If kubectl commands fail after infrastructure deployment:
```bash
cd infra
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) --overwrite-existing
```

### ArgoCD Image Updater Authentication Issues
If Image Updater cannot pull from ACR (authentication errors):
1. Verify ACR token secret exists: `kubectl get secret acr-credentials -n argocd`
2. Check Image Updater logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater`
3. Verify token hasn't expired (1-year default): `az acr token show --name image-updater-token --registry <acr-name>`
4. Re-run `terraform apply` to regenerate expired tokens

### Pipeline Variable Group Not Found
The infrastructure layer creates the variable group that the app pipeline uses. Ensure:
1. Infrastructure Deploy pipeline has completed successfully
2. Variable group exists in Azure DevOps project
3. Variable group is authorized for the App Deploy pipeline

## 📚 Documentation

- **[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)** - Complete step-by-step setup instructions
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed architecture documentation and design decisions
- **[QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Command reference and common operations
- **[PIPELINE_GUIDE.md](docs/PIPELINE_GUIDE.md)** - Azure DevOps pipeline usage and troubleshooting

## 📖 Additional Resources

### Official Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Azure DevOps Provider](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/)
- [Helm Documentation](https://helm.sh/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager](https://cert-manager.io/docs/)

### Architecture Diagrams
- [azure-resources-diagram.drawio.png](azure-resources-diagram.drawio.png) - High-level architecture flow

Open with [draw.io](https://app.diagrams.net) or draw.io desktop app.

## 👤 Author

**Serhii Nesterenko**

## 🚀 Quick Start Command

```bash
az login
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars # Put your PAT and DevOps org url there
terraform init && terraform apply
```

## 📂 Additional Documentation

Each directory contains its own README.md with specific details:
- [bootstrap/README.md](bootstrap/README.md) - Bootstrap layer details
- [infra/README.md](infra/README.md) - Infrastructure layer details
- [app/README.md](app/README.md) - Application layer details

---

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko

# Architecture Documentation

Complete architecture documentation for the Azure Infrastructure Automation project.

## System Overview

This project implements a four-layer GitOps architecture for enterprise-grade infrastructure automation on Azure:

1. **Bootstrap Layer** - Foundational infrastructure and CI/CD environment
2. **Infrastructure Layer** - Kubernetes platform with ArgoCD for GitOps
3. **Application Layer** - Docker image build pipeline
4. **Charts Layer** - Helm charts for GitOps-based deployments

## Architecture Diagrams

- `architecture-diagram.drawio` - High-level architecture flow

Open with draw.io desktop app or at https://app.diagrams.net
Or view architecture-diagram.drawio.png with preferred app

## Layer 1: Bootstrap

### Purpose
Creates foundational infrastructure required for all subsequent deployments.

### Components

#### Azure Storage Account
- **Name:** `tfstate[random]`
- **Purpose:** Terraform remote state storage
- **Type:** Standard LRS
- **Features:** Versioning enabled, TLS 1.2 minimum
- **Container:** `tfstate` (private access)

#### Build Agent VM
- **Name:** `vm-build-agent`
- **OS:** Ubuntu 22.04 LTS
- **Size:** Standard_B2s (2 vCPU, 4 GB RAM)
- **Purpose:** Self-hosted Azure Pipelines agent
- **Software:** Docker, Azure Pipelines agent
- **Authentication:** SSH key (RSA 4096)
- **Networking:** Public IP, NSG (SSH allowed)

#### Azure DevOps Project
- **Name:** Configurable (default: "TestProject")
- **Repositories:**
  - Infrastructure (Terraform code and pipelines)
  - Project name (Application code and Dockerfile, e.g., "TestProject")
  - Charts (Helm charts for ArgoCD GitOps deployments)
- **Pipelines:**
  - Infrastructure Deploy (deploys AKS, ACR, ArgoCD)
  - Infrastructure Destroy
  - App Deploy (builds and pushes Docker images to ACR)

#### Service Principal
- **Name:** `azdevops-<project_name>-service-connection` (e.g., `azdevops-TestProject-service-connection`)
- **Role:** Contributor on subscription
- **Purpose:** Pipeline authentication to Azure
- **Credential Expiry:** 2 years

#### Networking
- **VNet:** `vnet-build-agent` (10.0.0.0/16)
- **Subnet:** `subnet-build-agent` (10.0.1.0/24)
- **NSG:** SSH (port 22) allowed
- **Public IP:** Static, Standard SKU

### State Management
- Uses **local state** (terraform.tfstate)
- State contains sensitive data (SP credentials, SSH keys)
- Not shared with other layers

### Dependencies
- Azure subscription with Contributor access
- Azure DevOps organization with PAT

## Layer 2: Infrastructure

### Purpose
Deploys production-ready Kubernetes platform with ingress and SSL.

### Components

#### Azure Container Registry (ACR)
- **Name:** Configurable (must be globally unique)
- **SKU:** Basic (configurable)
- **Purpose:** Private Docker image registry
- **Integration:** Connected to AKS via AcrPull role
- **Login Server:** `[name].azurecr.io`
- **Token Authentication:** ACR token with scoped permissions for ArgoCD Image Updater

#### Azure Kubernetes Service (AKS)
- **Name:** `aks-cluster` (configurable)
- **Network Plugin:** Azure CNI
- **Network Policy:** Azure
- **DNS Prefix:** Configurable
- **Identity:** System Assigned Managed Identity

#### System Node Pool
- **Name:** system
- **Type:** VirtualMachineScaleSets
- **VM Size:** Standard_DS2_v2 (2 vCPU, 7 GB RAM)
- **OS Disk:** 30 GB
- **Autoscaling:** 1-3 nodes
- **Purpose:** System workloads and application pods

#### NGINX Ingress Controller
- **Deployment:** Helm chart (ingress-nginx)
- **Namespace:** ingress-nginx
- **Service Type:** LoadBalancer
- **Public IP:** Static (created separately)
- **Purpose:** HTTP/HTTPS traffic routing

#### Cert-Manager
- **Deployment:** Helm chart (cert-manager)
- **Namespace:** cert-manager
- **Issuer:** Let's Encrypt
- **Purpose:** Automatic SSL/TLS certificate management

#### ArgoCD
- **Deployment:** Helm chart (argo-cd)
- **Version:** 8.5.8
- **Namespace:** argocd
- **Web UI:** Accessible at `https://<fqdn>/argocd`
- **Authentication:** Admin password configured via Terraform (bcrypt hash)
- **Repository:** Connected to Azure DevOps Charts repository via HTTPS
- **Purpose:** GitOps continuous deployment

#### ArgoCD Image Updater
- **Deployment:** Helm chart (argocd-image-updater)
- **Version:** 1.0.2
- **Namespace:** argocd
- **Registry:** Configured for Azure Container Registry
- **Authentication:** ACR token with scoped permissions stored in Kubernetes secret
  - Token Scope: Repository metadata read and content read
  - Secret Name: `acr-credentials` (dockerconfigjson type)
  - Token Expiry: 1 year (configurable)
- **Update Strategy:** Digest-based for reliability
- **Configuration:** ImageUpdater CRD resources define which applications to monitor
- **Purpose:** Automatically detect and deploy new container images based on digest changes

#### Root ArgoCD Application
- **Deployment:** Helm chart (argocd-apps)
- **Pattern:** App of Apps
- **Source:** Charts repository, `root/` path
- **Sync Policy:** Automated with prune and self-heal
- **Purpose:** Bootstrap application deployments

#### Azure DevOps Integration
- **Service Connection:** References bootstrap SP
- **Variable Group:** Stores ACR, AKS, and network details
- **Purpose:** Enable app build pipeline

### State Management
- Uses **remote state** in Azure Blob Storage
- State key: `${project_name}.tfstate`
- Backend config passed via pipeline variables

### Dependencies
- Bootstrap layer deployed
- Build agent online
- Service principal available

## Layer 3: Application

### Purpose
Builds Docker images for deployment via GitOps.

### Components

#### Docker Image
- **Base:** nginx:alpine
- **Content:** Static HTML (index.html)
- **Port:** 80
- **Registry:** Azure Container Registry (ACR)
- **Tagging:** Build ID and `latest`

#### CI/CD Pipeline
- **Trigger:** Git push to master branch
- **Stages:** Build → Push to ACR
- **Agent:** Self-hosted (Default pool)
- **Service Connection:** acr-rbac-connection

### State Management
- No Terraform state (Docker image build only)

### Dependencies
- Infrastructure layer deployed
- ACR available
- Build agent online

## Layer 4: Charts (GitOps)

### Purpose
Defines Helm charts for ArgoCD-based deployments.

### Components

#### Root Application Chart
- **Location:** `charts/root/`
- **Type:** ArgoCD Application (App of Apps pattern)
- **Purpose:** Manages child applications
- **Values:** ACR URL, hostname, TLS secret name, Charts repository URL
- **Resources:**
  - Application CRD for each app (test application)
  - ImageUpdater CRD for automatic image digest-based updates

#### Test Application Chart
- **Location:** `charts/test/`
- **Type:** Standard Helm chart
- **Templates:**
  - Deployment (with configurable replicas, image, resources)
  - Service (ClusterIP type, port 80)
  - Ingress (NGINX class, TLS enabled)
  - HorizontalPodAutoscaler (optional)
- **Image Updates:** Managed by ImageUpdater CRD in root chart (digest-based updates)

#### ImageUpdater Resource (Root Chart)
- **Location:** `charts/root/templates/imageupdater.yaml`
- **Type:** Custom Resource Definition (CRD)
- **API Version:** `argocd-image-updater.argoproj.io/v1alpha1`
- **Kind:** ImageUpdater
- **Configuration:**
  - **Target Application:** Monitors the "test" application via namePattern
  - **Image Tracking:** Watches ACR test image for changes
  - **Update Strategy:** `digest` - Updates when image digest changes, even with same tag
  - **Tag Filter:** Only monitors the tag specified in values (e.g., "latest")
  - **Write-back Method:** `argocd` - Directly updates Application spec in ArgoCD
- **Behavior:** Automatically detects when a new image with the same tag but different digest is pushed to ACR, then updates the Application to trigger a rolling deployment

#### Kubernetes Resources (Deployed by ArgoCD)
- **Deployment:**
  - Replicas: 1 (configurable)
  - Strategy: RollingUpdate
  - Image: Pulled from ACR
  - Health Checks: Liveness and readiness probes
- **Service:**
  - Type: ClusterIP
  - Port: 80
- **Ingress:**
  - Class: nginx
  - TLS: Certificate from cert-manager
  - Host: Configurable FQDN

### State Management
- No Terraform state (managed by ArgoCD)

### Dependencies
- Infrastructure layer deployed (ArgoCD running)
- Charts repository initialized
- Root application deployed via Terraform

## Data Flow

### Bootstrap Flow
```
Terraform Apply
  ↓
Create Storage Account
  ↓
Create VNet, Subnet, NSG, Public IP
  ↓
Create VM with SSH key
  ↓
Install Docker on VM
  ↓
Download and configure Azure Pipelines agent
  ↓
Create Azure DevOps Project
  ↓
Initialize Git repositories
  ↓
Push infra and app code
  ↓
Create Service Principal
  ↓
Create Service Connection
  ↓
Create 3 pipelines with authorizations
  ↓
Ready for infrastructure deployment
```

### Infrastructure Deployment Flow
```
Run "Infrastructure Deploy" Pipeline
  ↓
Initialize Terraform with remote backend
  ↓
Validate and plan infrastructure
  ↓
Create Resource Group
  ↓
Create ACR
  ↓
Create AKS cluster with system node pool
  ↓
Assign AcrPull role to AKS
  ↓
Create static public IP with FQDN
  ↓
Deploy NGINX ingress controller (Helm)
  ↓
Deploy cert-manager (Helm)
  ↓
Deploy ArgoCD (Helm)
  ↓
Configure ArgoCD with Azure DevOps repository
  ↓
Create ACR token with scoped permissions
  ↓
Create Kubernetes secret with ACR token
  ↓
Deploy ArgoCD Image Updater (Helm)
  ↓
Deploy Root ArgoCD Application (Helm)
  ↓
Root app creates child applications (test)
  ↓
ArgoCD deploys application from Charts repo
  ↓
Create ACR and AKS service connections
  ↓
Create variable group with outputs
  ↓
Application running in AKS via GitOps
```

### Application Deployment Flow (GitOps)
```
Developer pushes code to App repository
  ↓
"App Deploy" Pipeline triggers
  ↓
Build Docker image from Dockerfile
  ↓
Tag image with build ID and 'latest'
  ↓
Authenticate to ACR
  ↓
Push image to ACR
  ↓
ImageUpdater CRD watches ACR for digest changes
  ↓
ArgoCD Image Updater controller detects new digest
  ↓
Updates Application spec with new image digest
  ↓
ArgoCD detects configuration drift
  ↓
Syncs Helm chart from Charts repository
  ↓
Updates Kubernetes deployment
  ↓
Rolling update replaces pods
  ↓
NGINX routes traffic to new pods
  ↓
Application updated (zero manual intervention)
```

### Chart Update Flow
```
Developer updates Helm chart in Charts repository
  ↓
Git push to Charts repository
  ↓
ArgoCD polls Charts repository
  ↓
Detects changes in Helm chart
  ↓
Syncs application to desired state
  ↓
Updates Kubernetes resources
  ↓
Changes applied to AKS cluster
```

## Security Architecture

### Authentication & Authorization
- **Azure:** Service Principal with Contributor role
- **AKS:** System Assigned Managed Identity
- **ACR:**
  - Role-based access (AcrPull for AKS kubelet)
  - Token-based authentication for ArgoCD Image Updater
- **ACR Token:**
  - Scoped permissions (repository metadata/content read)
  - 1-year expiry
  - Stored in Kubernetes secret (argocd/acr-credentials)
- **Build Agent:** SSH key-based authentication
- **Azure DevOps:** PAT token for git operations and ArgoCD repository access
- **ArgoCD:** Admin password configured via Terraform (bcrypt hash)
- **ArgoCD Repositories:** HTTPS authentication with PAT token

### Network Security
- **Build Agent:** NSG restricts access to SSH only
- **AKS:** Azure CNI with network policy
- **Ingress:** TLS 1.2 minimum via cert-manager
- **ACR:** Private registry, accessible only to AKS

### Secret Management
- **PAT Token:** Stored in pipeline variables (secret) and ArgoCD repository config
- **Service Principal:** Credentials in service connection
- **SSH Key:** Generated locally, not committed
- **Terraform State:** Encrypted in Azure Blob Storage
- **ArgoCD Admin Password:** Stored as bcrypt hash in Terraform variable
- **Azure DevOps SSH Keys:** Retrieved via ssh-keyscan for ArgoCD known hosts
- **ACR Token:**
  - Generated via Terraform (azurerm_container_registry_token_password)
  - Stored in Kubernetes secret (type: dockerconfigjson)
  - Managed lifecycle via Terraform
  - Requires rotation before 1-year expiry

### Compliance
- TLS 1.2 minimum on storage accounts
- Blob versioning for state history
- Private repositories in Azure DevOps
- Role-based access control (RBAC)

## Scalability

### Horizontal Scaling
- **AKS Nodes:** Autoscale 1-3 nodes (configurable)
- **Application Pods:** 2 replicas (configurable via deployment)
- **Build Agents:** Can add more agents to pool

### Vertical Scaling
- **Node Pool:** Change VM size in variables
- **Storage:** LRS to GRS/ZRS upgrade supported
- **ACR:** Basic to Standard/Premium upgrade supported

## High Availability

### Infrastructure Layer
- **AKS:** Multiple nodes in system pool
- **NGINX Ingress:** Multiple replicas
- **Storage Account:** LRS (local redundancy)

### Application Layer
- **Deployment:** 1 replica (configurable in deployment.yaml)
- **Rolling Updates:** Zero downtime deployments
- **Health Checks:** Automatic pod restart

### Limitations
- Single region deployment
- No geo-redundancy in current design
- Manual disaster recovery required

## Monitoring & Observability

### Built-in Monitoring
- **Azure Monitor:** Enabled on all resources
- **AKS Diagnostics:** Logs sent to Azure Monitor
- **Container Insights:** Available for AKS

### Built-in GitOps Monitoring
- **ArgoCD UI:** Real-time application sync status
- **ArgoCD Notifications:** Sync status and health alerts
- **Image Updater Logs:** Image update detection and processing

### Recommended Additions
- Application Insights for app monitoring
- Log Analytics workspace for centralized logging
- Prometheus/Grafana for Kubernetes and ArgoCD metrics
- Alerting rules for critical events and ArgoCD sync failures

## Cost Optimization

### Current Configuration
- **Build Agent:** Standard_B2s (~$30/month)
- **AKS Nodes:** 1-3x Standard_DS2_v2 (~$70-210/month)
- **ACR:** Basic SKU (~$5/month)
- **Storage:** LRS with minimal usage (~$1/month)
- **Public IPs:** 2x Static (~$8/month)

**Estimated Monthly Cost:** $114-254 USD

### Optimization Strategies
- Use burstable VMs for non-production
- Implement autoscaling policies
- Delete non-production environments overnight
- Use Azure Reservations for committed usage
- Consider spot instances for dev/test

## Disaster Recovery

### Backup Strategy
- **State Files:** Blob versioning enabled for Terraform state
- **Helm Charts:** Stored in Azure DevOps Charts repository
- **Application Code:** Stored in Azure DevOps App repository
- **Infrastructure Code:** Stored in Azure DevOps Infrastructure repository
- **Container Images:** Stored in ACR (consider geo-replication for Premium SKU)
- **ArgoCD Configuration:** Declarative configuration in Terraform

### Recovery Procedures
1. Restore state file from blob version history
2. Re-run terraform apply for infrastructure (includes ArgoCD deployment)
3. ArgoCD automatically deploys applications from Charts repository
4. If needed, trigger App pipeline to rebuild Docker images
5. Restore persistent data (if applicable)

### RPO/RTO
- **Recovery Point Objective (RPO):** Last committed code
- **Recovery Time Objective (RTO):** 30-60 minutes

---

© 2025 Serhii Nesterenko

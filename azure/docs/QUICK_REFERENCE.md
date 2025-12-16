# Quick Reference

Fast reference guide for common commands and operations.

## Quick Start

```bash
# 1. Bootstrap (from this project)
cd bootstrap
terraform init && terraform apply

# 2. Clone repositories from Azure DevOps (IMPORTANT!)
cd ~/workspace
git clone https://<pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
git clone https://<pat>@dev.azure.com/<org>/<project>/_git/<ProjectName>

# 3. Infrastructure (Pipeline - Recommended)
# Go to Azure DevOps → Run "Infrastructure Deploy"

# 3. Infrastructure (Manual - from cloned repo)
cd ~/workspace/Infrastructure
terraform init && terraform apply

# 4. Application (GitOps - automatic deployment)
# ArgoCD automatically deploys from Charts repository
# To update: push code changes to App repo, pipeline builds image, ArgoCD deploys
cd ~/workspace/<ProjectName>
git add .
git commit -m "Update app"
git push
```

## Bootstrap Commands

```bash
# Deploy
cd bootstrap
terraform init
terraform apply

# View outputs
terraform output
terraform output -raw build_agent_public_ip
terraform output project_url

# SSH to build agent
ssh -i agent_ssh_key.pem azureuser@$(terraform output -raw build_agent_public_ip)

# Check agent status (on VM)
cd ~/agent && sudo ./svc.sh status

# Destroy
terraform destroy
```

## Infrastructure Commands

**Note:** Run these from the cloned Infrastructure repository, NOT from the local infra/ folder.

```bash
# Deploy (from cloned Infrastructure repository)
cd ~/workspace/Infrastructure
terraform init
terraform apply

# View outputs
terraform output
terraform output -raw acr_login_server
terraform output -raw aks_cluster_name

# Destroy
terraform destroy
```

## Azure CLI Commands

```bash
# Login
az login
az account show
az account set --subscription "Subscription-Name"

# ACR
az acr login --name <acr-name>
az acr repository list --name <acr-name>
az acr repository show-tags --name <acr-name> --repository <repo-name>

# ACR Tokens
az acr token list --registry <acr-name>
az acr token show --name <token-name> --registry <acr-name>
az acr token show --name image-updater-token --registry <acr-name> --query "credentials.passwords[0].expiry"

# AKS
az aks list --output table
az aks show --resource-group <rg-name> --name <aks-name>
az aks get-credentials --resource-group <rg-name> --name <aks-name>
az aks browse --resource-group <rg-name> --name <aks-name>

# Resource Groups
az group list --output table
az group show --name <rg-name>
az group delete --name <rg-name> --yes --no-wait
```

## Kubernetes Commands

```bash
# Get AKS credentials and set kubectl context
az aks get-credentials \
  --resource-group <rg-name> \
  --name <aks-name> \
  --overwrite-existing

# Alternative: Using Terraform outputs
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl version

# Context management
kubectl config get-contexts                    # List all contexts
kubectl config current-context                 # Show current context
kubectl config use-context <context-name>      # Switch context
kubectl config view                            # View kubeconfig

# Namespaces
kubectl get namespaces
kubectl get all -n <namespace>

# Pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
kubectl exec -it <pod-name> -- /bin/bash

# Deployments
kubectl get deployments
kubectl describe deployment <deployment-name>
kubectl scale deployment <deployment-name> --replicas=3
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>

# Services
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints

# Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# ConfigMaps & Secrets
kubectl get configmaps
kubectl get secrets
kubectl describe secret <secret-name>

# ArgoCD commands
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
kubectl get imageupdaters -n argocd
kubectl describe imageupdater <imageupdater-name> -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater

# ArgoCD Image Updater - ACR authentication
kubectl get secret acr-credentials -n argocd
kubectl describe secret acr-credentials -n argocd

# Manual manifest operations (if needed)
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>

# Troubleshooting
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl top nodes
kubectl top pods
```

## Docker Commands

```bash
# Build
docker build -t <image-name>:<tag> .
docker build -t <acr-name>.azurecr.io/<image-name>:<tag> .

# Tag
docker tag <source-image>:<tag> <target-image>:<tag>

# Push to ACR
az acr login --name <acr-name>
docker push <acr-name>.azurecr.io/<image-name>:<tag>

# Pull from ACR
docker pull <acr-name>.azurecr.io/<image-name>:<tag>

# Local operations
docker images
docker ps
docker ps -a
docker logs <container-id>
docker exec -it <container-id> /bin/bash
docker rm <container-id>
docker rmi <image-id>
docker system prune -a  # Clean up
```

## Azure DevOps CLI Commands

```bash
# Login
az devops login

# Configure defaults
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>

# Pipelines
az pipelines list
az pipelines run --name "Infrastructure Deploy"
az pipelines show --name "Infrastructure Deploy"
az pipelines runs list
az pipelines runs show --id <run-id>

# Repositories
az repos list
az repos show --repository <repo-name>

# Service connections
az devops service-endpoint list
az devops service-endpoint show --id <connection-id>
```

## Terraform Commands

```bash
# Initialize
terraform init
terraform init -reconfigure
terraform init -upgrade

# Plan
terraform plan
terraform plan -out=tfplan
terraform plan -destroy

# Apply
terraform apply
terraform apply tfplan
terraform apply -auto-approve

# Destroy
terraform destroy
terraform destroy -auto-approve
terraform destroy -target=<resource>

# State
terraform state list
terraform state show <resource>
terraform state rm <resource>
terraform state pull
terraform state push

# Outputs
terraform output
terraform output <output-name>
terraform output -raw <output-name>
terraform output -json

# Format & Validate
terraform fmt
terraform fmt -recursive
terraform validate

# Workspace
terraform workspace list
terraform workspace new <name>
terraform workspace select <name>

# Import
terraform import <resource-type>.<name> <azure-resource-id>
```

## Git Commands

```bash
# Clone Azure DevOps repository
git clone https://<pat>@dev.azure.com/<org>/<project>/_git/<repo>

# Basic operations
git status
git add .
git commit -m "message"
git push
git pull

# Branches
git branch
git checkout -b <branch-name>
git checkout <branch-name>
git merge <branch-name>
git branch -d <branch-name>

# Remote
git remote -v
git remote add origin <url>
git remote set-url origin <url>
```

## Useful One-Liners

```bash
# Get ingress IP
kubectl get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'

# Get all pods with custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# Watch pod status
watch kubectl get pods

# Get pod resource usage
kubectl top pods --all-namespaces

# Port forward
kubectl port-forward <pod-name> 8080:80

# Get service account token
kubectl get secret <secret-name> -o jsonpath='{.data.token}' | base64 --decode

# Delete all pods in namespace
kubectl delete pods --all -n <namespace>

# Get events sorted
kubectl get events --sort-by='.lastTimestamp'

# Shell into pod
kubectl exec -it <pod-name> -- sh

# Copy files to/from pod
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file
```

## Environment Variables

```bash
# Azure
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"

# Kubernetes
export KUBECONFIG=~/.kube/config

# Azure DevOps
export AZURE_DEVOPS_EXT_PAT="<pat-token>"
```

## Configuration File Locations

```bash
# Terraform
~/.terraform.d/
~/.terraformrc
.terraform/
terraform.tfstate
terraform.tfvars

# Kubernetes
~/.kube/config

# Azure CLI
~/.azure/

# Docker
~/.docker/config.json

# SSH
~/.ssh/
```

## Common Troubleshooting

```bash
# Reset kubeconfig
az aks get-credentials --resource-group <rg> --name <aks> --overwrite-existing

# Re-authenticate to ACR
az acr login --name <acr-name>

# Check ACR token expiry
az acr token show --name image-updater-token --registry <acr-name> --query "credentials.passwords[0].expiry"

# Verify ACR credentials secret in ArgoCD
kubectl get secret acr-credentials -n argocd
kubectl describe secret acr-credentials -n argocd

# Check ArgoCD Image Updater logs for authentication errors
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=100

# Check Terraform state lock
# Go to Azure Portal → Storage Account → Containers → tfstate → *.tfstate → Lease status

# Restart AKS pods
kubectl rollout restart deployment/<deployment-name>

# View pod logs from previous instance
kubectl logs <pod-name> --previous

# Debug pod networking
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Check cluster DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

## URLs

```bash
# Azure Portal
https://portal.azure.com

# Azure DevOps
https://dev.azure.com/<organization>

# Kubernetes Dashboard (if enabled)
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## File Patterns

```bash
# .gitignore patterns
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
*.pem
.env

# Files to never commit
agent_ssh_key.pem
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
.terraform.lock.hcl (optional)
```

---

© 2025 Serhii Nesterenko

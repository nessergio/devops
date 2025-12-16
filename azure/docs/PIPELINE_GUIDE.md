# Pipeline Guide

Complete guide for working with Azure DevOps pipelines in this project.

## Pipeline Overview

The project includes three automated pipelines for GitOps-based deployments:

1. **Infrastructure Deploy** - Deploys Azure infrastructure with ArgoCD
2. **Infrastructure Destroy** - Destroys Azure infrastructure
3. **App Deploy** - Builds and pushes Docker images to ACR (triggers GitOps deployment)

## Infrastructure Deploy Pipeline

### Location
`infra/pipelines/deploy.yml`

### Purpose
Deploys ACR, AKS, ingress controller, cert-manager, ArgoCD, and bootstraps GitOps deployments to Azure.

### Trigger
- Manual execution from Azure DevOps UI
- Can be configured for git branch triggers

### Stages

#### 1. Validate
- Checks Terraform formatting (`terraform fmt -check`)
- Validates Terraform configuration (`terraform validate`)
- Ensures code quality before deployment

#### 2. Plan
- Initializes Terraform with remote backend
- Generates execution plan (`terraform plan`)
- Outputs plan for review
- No changes made to infrastructure

#### 3. Apply
- **Requires manual approval**
- Applies Terraform configuration (`terraform apply -auto-approve`)
- Creates/updates Azure resources (ACR, AKS, ingress, cert-manager)
- Deploys ArgoCD, ArgoCD Image Updater, and Root Application
- ArgoCD bootstraps application deployment from Charts repository
- Saves outputs for app build pipeline

### Variables

Automatically set by bootstrap layer:
- `TF_STATE_RESOURCE_GROUP` - State storage resource group
- `TF_STATE_STORAGE_ACCOUNT` - State storage account name
- `TF_STATE_CONTAINER_NAME` - State container name
- `TF_STATE_KEY` - State file key
- `AZDO_PERSONAL_ACCESS_TOKEN` - Azure DevOps PAT (secret)
- `AZDO_ORG_SERVICE_URL` - Azure DevOps organization URL

### Service Connection
Uses `Azure-ServiceConnection` service connection created by bootstrap.

### Agent Pool
Runs on self-hosted agent (Default pool).

### Running the Pipeline

1. Navigate to Azure DevOps → Pipelines
2. Select "Infrastructure Deploy"
3. Click "Run pipeline"
4. Select branch (default: master)
5. Click "Run"
6. Wait for Validate and Plan stages
7. Review plan output
8. Approve Apply stage
9. Wait for completion (~15-20 minutes)

### Success Indicators
- All stages show green checkmarks
- Terraform outputs displayed
- Variable group created
- "App Deploy" pipeline automatically triggered

## Infrastructure Destroy Pipeline

### Location
`infra/pipelines/destroy.yml`

### Purpose
Safely destroys all Azure infrastructure resources.

### Trigger
- Manual execution only
- No automatic triggers (safety measure)

### Stages

#### 1. Validate
- Checks Terraform formatting
- Validates configuration

#### 2. Plan Destroy
- Initializes Terraform with remote backend
- Generates destruction plan (`terraform plan -destroy`)
- Shows what will be deleted
- No resources destroyed yet

#### 3. Destroy
- **Requires manual approval**
- Destroys infrastructure (`terraform destroy -auto-approve`)
- Removes all Azure resources
- Preserves Terraform state

### Variables
Same as Infrastructure Deploy pipeline.

### Running the Pipeline

1. Navigate to Azure DevOps → Pipelines
2. Select "Infrastructure Destroy"
3. Click "Run pipeline"
4. Review destruction plan carefully
5. Approve Destroy stage (if certain)
6. Wait for completion (~10-15 minutes)

### Warning
This is a **destructive operation**. Ensure you:
- Have backups of important data
- Notify team members
- Understand this will delete AKS cluster and ACR
- Application will become unavailable

## App Deploy Pipeline

### Location
`app/pipelines/azure-pipelines.yaml`

### Purpose
Builds Docker image, pushes to ACR, and deploys to AKS.

### Trigger
- **Automatic:** Runs after "Infrastructure Deploy" completes successfully
- **Manual:** Can be triggered from Azure DevOps UI

### Stages

#### 1. Build
- Builds Docker image from `app/Dockerfile`
- Tags image with build ID and `latest`
- Pushes image to Azure Container Registry
- Uses Docker task with ACR service connection

#### 2. GitOps Deployment (Automatic)
After the image is pushed to ACR:
- ArgoCD Image Updater polls ACR for new images
- Detects new image digest
- Updates ArgoCD Application with new image tag
- ArgoCD syncs Helm chart from Charts repository
- Rolling update deploys new pods to AKS
- **No manual deployment steps required**

### Variables

From Variable Group (created by infrastructure layer):
- `ACR_NAME` - Container registry name
- `ACR_LOGIN_SERVER` - ACR login server URL
- `imageRepository` - Docker image repository name (e.g., "test")
- `TAG` - Build ID used for image tagging

### Service Connection
Uses `acr-rbac-connection` service connection created by infrastructure layer.

### Agent Pool
Runs on self-hosted agent with Docker installed.

### Monitoring Deployment

After the pipeline completes:
1. Access ArgoCD UI at `https://<your-fqdn>/argocd`
2. Login with admin credentials (configured in infrastructure)
3. View real-time sync status and application health
4. Check Image Updater logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater`

### Running the Pipeline Manually

1. Navigate to Azure DevOps → Pipelines
2. Select "App Deploy"
3. Click "Run pipeline"
4. Select branch (default: master)
5. Click "Run"
6. Wait for image build (~2-3 minutes)
7. ArgoCD will automatically deploy the new image (check ArgoCD UI for status)

### Success Indicators
- Docker image pushed to ACR
- Kubernetes deployment updated
- Pods running successfully
- Application accessible via ingress IP

## Pipeline Best Practices

### Before Running Pipelines

1. **Check Build Agent Status**
   ```bash
   # From bootstrap directory
   ssh -i agent_ssh_key.pem azureuser@$(terraform output -raw build_agent_public_ip)
   cd ~/agent
   sudo ./svc.sh status
   ```

2. **Verify Service Connection**
   - Go to Project Settings → Service connections
   - Ensure "Azure-ServiceConnection" shows green checkmark (created by bootstrap)
   - After infrastructure deployment, verify "acr-rbac-connection" and "kubernetes-rbac-connection" also exist

3. **Review Variable Groups**
   - Go to Pipelines → Library
   - Verify variable group has correct values

### During Pipeline Execution

1. **Monitor Logs**
   - Click on running pipeline
   - View real-time logs for each task
   - Check for warnings or errors

2. **Review Plans**
   - Always review Terraform plan output
   - Verify expected resources
   - Check for unexpected deletions

3. **Approval Gates**
   - Don't rush approvals
   - Verify plan output matches expectations
   - Ensure no team members are working on same resources

### After Pipeline Completion

1. **Verify Deployment**
   ```bash
   # For infrastructure
   kubectl get nodes
   kubectl get pods --all-namespaces

   # For application
   kubectl get pods
   kubectl get ingress
   ```

2. **Check Outputs**
   - View pipeline run summary
   - Note any warnings
   - Save important output values

3. **Test Functionality**
   - Access application via ingress IP
   - Verify SSL certificate
   - Check application logs

## Pipeline Troubleshooting

### Pipeline Fails: Agent Not Available

**Symptoms:** Pipeline queued but never starts

**Solution:**
```bash
# SSH to build agent
ssh -i agent_ssh_key.pem azureuser@<build-agent-ip>

# Check agent status
cd ~/agent
sudo ./svc.sh status

# Restart if needed
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Pipeline Fails: Authentication Error

**Symptoms:** "Could not authenticate with Azure"

**Solution:**
1. Check service connection in Azure DevOps
2. Verify service principal hasn't expired
3. Re-run bootstrap to recreate service connection

### Pipeline Fails: Terraform State Locked

**Symptoms:** "Error acquiring state lock"

**Solution:**
1. Wait for other operations to complete
2. Or break lease in Azure Portal:
   - Navigate to Storage Account → Containers → tfstate
   - Find state file → Properties → Break lease

### Pipeline Fails: Backend Initialization Error

**Symptoms:** "Failed to configure backend"

**Solution:**
- Verify storage account exists
- Check pipeline variables are correct
- Ensure build agent has network access to storage

### Pipeline Fails: Kubernetes Connection Error

**Symptoms:** "Unable to connect to cluster"

**Solution:**
```bash
# Verify AKS is running
az aks show --resource-group <rg> --name <aks-cluster>

# Check service connection has access
# Re-run infrastructure deploy if needed
```

### Pipeline Fails: Docker Build Error

**Symptoms:** "Error building Docker image"

**Solution:**
1. Verify Dockerfile syntax
2. Check base image is accessible
3. Ensure build agent has Docker installed
4. Verify sufficient disk space on agent

### Pipeline Fails: ACR Push Error

**Symptoms:** "Failed to push image"

**Solution:**
1. Verify ACR exists and is accessible
2. Check service connection has push permissions
3. Ensure ACR name in variables is correct

## Pipeline Customization

### Adding Environment Variables

Edit pipeline YAML:
```yaml
variables:
  - name: MY_VARIABLE
    value: 'my-value'
```

### Adding Manual Approval

Add approval gate in Azure DevOps UI:
1. Pipelines → Select pipeline → Edit
2. Click on stage → Pre-deployment conditions
3. Enable "Pre-deployment approvals"
4. Add approvers

### Changing Trigger Behavior

Edit pipeline YAML:
```yaml
trigger:
  branches:
    include:
      - master
      - develop
  paths:
    include:
      - infra/*
```

### Adding Email Notifications

1. Project Settings → Notifications
2. Create new subscription
3. Select "Build completed" event
4. Filter by pipeline name

## Pipeline Performance

### Typical Execution Times

- **Infrastructure Deploy:** 15-20 minutes
  - Validate: 1-2 minutes
  - Plan: 3-5 minutes
  - Apply: 10-15 minutes

- **Infrastructure Destroy:** 10-15 minutes
  - Validate: 1-2 minutes
  - Plan Destroy: 2-3 minutes
  - Destroy: 7-10 minutes

- **App Deploy:** 5-10 minutes
  - Build: 3-5 minutes
  - Deploy: 2-5 minutes

### Optimization Tips

1. Use pipeline caching for Docker layers
2. Parallelize independent tasks
3. Use smaller Terraform plan scope when possible
4. Keep Docker images small
5. Use resource tags for faster queries

## Security Considerations

### Secret Management
- PAT tokens stored as secret variables
- Service principal credentials in service connection
- Never log secrets in pipeline output
- Rotate credentials regularly

### Access Control
- Limit pipeline editing to authorized users
- Require approval for production deployments
- Use separate service connections per environment
- Enable audit logging

### Best Practices
- Always review plans before applying
- Use branch policies to require reviews
- Enable pipeline YAML schema validation
- Test in non-production first
- Implement rollback procedures

---

© 2025 Serhii Nesterenko

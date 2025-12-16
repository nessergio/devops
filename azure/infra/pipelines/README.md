# Infrastructure Pipelines

Azure DevOps pipeline definitions for infrastructure deployment and destruction.

## Pipelines

### deploy.yml
Deploys infrastructure to Azure.

**Stages:**
1. Validate - Terraform fmt and validate
2. Plan - Generate execution plan
3. Apply - Deploy infrastructure (manual approval)

**Trigger:** Manual

**Variables:**
- `TF_STATE_RESOURCE_GROUP` - State storage resource group
- `TF_STATE_STORAGE_ACCOUNT` - State storage account name
- `TF_STATE_CONTAINER_NAME` - State container name
- `TF_STATE_KEY` - State file key
- `AZDO_PERSONAL_ACCESS_TOKEN` - Azure DevOps PAT (secret)
- `AZDO_ORG_SERVICE_URL` - Azure DevOps org URL

### destroy.yml
Destroys infrastructure from Azure.

**Stages:**
1. Validate - Terraform fmt and validate
2. Plan Destroy - Generate destruction plan
3. Destroy - Remove infrastructure (manual approval)

**Trigger:** Manual

**Variables:** Same as deploy.yml

## Usage

1. Navigate to Azure DevOps project → Pipelines
2. Select "Infrastructure Deploy" or "Infrastructure Destroy"
3. Click "Run pipeline"
4. Review plan and approve deployment/destruction

## Notes

- All variables are set automatically by bootstrap layer
- Pipelines run on self-hosted agent (Default pool)
- Manual approval required before apply/destroy
- State is stored in Azure Blob Storage

---

© 2025 Serhii Nesterenko

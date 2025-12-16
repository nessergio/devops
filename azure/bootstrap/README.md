# Bootstrap Layer

Creates foundational infrastructure for the entire project.

## What This Creates

- **Azure Storage Account** - Terraform remote state storage with versioning
- **Build Agent VM** - Self-hosted Azure Pipelines agent (Ubuntu 22.04 + Docker)
- **Azure DevOps Project** - Project with 3 Git repositories (Infrastructure, App, Charts) and 3 pipelines
- **Service Principal** - Azure AD service principal with Contributor role
- **Service Connection** - Azure DevOps connection for pipeline authentication
- **Networking** - VNet, Subnet, NSG, Public IP for build agent

## Usage

```bash
# Configure credentials
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure DevOps PAT and org URL

# Deploy
terraform init
terraform apply

# View outputs
terraform output
```

## Key Files

- `1_storage.tf` - State storage account and blob container
- `1_build_agent.tf` - Build agent VM with Azure Pipelines agent installation
- `2_project.tf` - Azure DevOps project, repositories, and pipelines
- `2_service_connections.tf` - Service principal and service connection
- `modules/devops_project/` - Reusable module for project and repo initialization

## Outputs

- `project_url` - Azure DevOps project URL
- `storage_account_name` - State storage account name
- `build_agent_public_ip` - Build agent VM public IP
- `azure_service_connection_name` - Service connection name

## State Management

Uses **local state** (no backend configured) - this is intentional as it creates the state storage for other layers.

## Important

- Run this **first** before deploying infrastructure layer
- SSH key saved as `agent_ssh_key.pem` (do not commit)
- State file `terraform.tfstate` contains sensitive data (do not commit)

---

© 2025 Serhii Nesterenko

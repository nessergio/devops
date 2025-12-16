# DevOps Project Module

Reusable Terraform module for creating Azure DevOps projects with initialized Git repositories.

## What This Module Does

- Creates Azure DevOps project with configurable features
- Initializes Git repositories with provided source code
- Pushes code to repositories automatically using PAT authentication
- Configures repository permissions for build service

## Usage

```hcl
module "project" {
  source = "./modules/devops_project"

  project_name        = "Infrastructure"
  project_description = "Infrastructure as Code"
  azure_devops_pat    = var.azure_devops_pat
  visibility          = "private"
  work_item_template  = "Agile"

  features = {
    "boards"       = "enabled"
    "repositories" = "enabled"
    "pipelines"    = "enabled"
    "testplans"    = "disabled"
  }

  source_directory_infra = "../infra"
  source_directory_app   = "../app"
  commit_message         = "Initial commit"
  readme_content         = "# Project README"
}
```

## Key Features

- Automatic repository initialization with source code
- PAT-based authentication for git operations
- Configurable project features (boards, repos, pipelines)
- Repository permissions management
- Returns project and repository IDs for pipeline configuration

## Outputs

- `project_id` - Azure DevOps project ID
- `repository_infra_id` - Infrastructure repository ID
- `repository_app_id` - Application repository ID

---

© 2025 Serhii Nesterenko

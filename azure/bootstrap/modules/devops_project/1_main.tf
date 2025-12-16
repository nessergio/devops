# Create Azure DevOps Project
resource "azuredevops_project" "project" {
  name               = var.project_name
  description        = var.project_description
  visibility         = var.visibility
  version_control    = "Git"
  work_item_template = var.work_item_template

  features = var.features
}

# Create Git Repository
resource "azuredevops_git_repository" "infra" {
  project_id = azuredevops_project.project.id
  name       = "Infrastructure"
  initialization {
    init_type = "Clean"
  }
}

# Create Git Repository
resource "azuredevops_git_repository" "charts" {
  project_id = azuredevops_project.project.id
  name       = "Charts"
  initialization {
    init_type = "Clean"
  }
}

# Reference to the default project repository created automatically by Azure DevOps
data "azuredevops_git_repository" "app" {
  project_id = azuredevops_project.project.id
  name       = var.project_name
}

# Push files from source directory to repository
resource "null_resource" "push_to_infra_repo" {
  count = var.source_directory_infra != "" ? 1 : 0

  triggers = {
    repo_id    = azuredevops_git_repository.infra.id
    always_run = var.force_push ? timestamp() : "once"
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/push-to-repo.sh"
    environment = {
      REPO_URL         = azuredevops_git_repository.infra.web_url
      AZURE_DEVOPS_PAT = var.azure_devops_pat
      SOURCE_DIR       = var.source_directory_infra
      COMMIT_MESSAGE   = var.commit_message
      README_CONTENT   = var.auto_generate_readme ? var.readme_content : ""
    }
  }

  depends_on = [
    null_resource.push_to_infra_repo
  ]
}

# Push files from source directory to repository
resource "null_resource" "push_to_charts_repo" {
  count = var.source_directory_charts != "" ? 1 : 0

  depends_on = [
    azuredevops_git_repository.charts
  ]

  triggers = {
    repo_id    = azuredevops_git_repository.charts.id
    always_run = var.force_push ? timestamp() : "once"
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/push-to-repo.sh"
    environment = {
      REPO_URL         = azuredevops_git_repository.charts.web_url
      AZURE_DEVOPS_PAT = var.azure_devops_pat
      SOURCE_DIR       = var.source_directory_charts
      COMMIT_MESSAGE   = var.commit_message
      README_CONTENT   = var.auto_generate_readme ? var.readme_content : ""
    }
  }
}

# Push files from source directory to repository
resource "null_resource" "push_to_app_repo" {
  count = var.source_directory_app != "" ? 1 : 0

  triggers = {
    repo_id    = data.azuredevops_git_repository.app.id
    always_run = var.force_push ? timestamp() : "once"
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/push-to-repo.sh"
    environment = {
      REPO_URL         = data.azuredevops_git_repository.app.web_url
      AZURE_DEVOPS_PAT = var.azure_devops_pat
      SOURCE_DIR       = var.source_directory_app
      COMMIT_MESSAGE   = var.commit_message
      README_CONTENT   = var.auto_generate_readme ? var.readme_content : ""
    }
  }

  depends_on = [
    null_resource.push_to_charts_repo
  ]
}

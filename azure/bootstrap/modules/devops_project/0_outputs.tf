output "project_id" {
  description = "The ID of the Azure DevOps project"
  value       = azuredevops_project.project.id
}

output "project_name" {
  description = "The name of the Azure DevOps project"
  value       = azuredevops_project.project.name
}

output "project_url" {
  description = "The URL of the Azure DevOps project"
  value       = azuredevops_project.project.id
}

output "repository_infra_id" {
  description = "The ID of the Git repository"
  value       = azuredevops_git_repository.infra.id
}

output "repository_infra_name" {
  description = "The name of the Git repository"
  value       = azuredevops_git_repository.infra.name
}

output "repository_infra_url" {
  description = "The clone URL of the Git repository"
  value       = azuredevops_git_repository.infra.remote_url
}

output "repository_infra_web_url" {
  description = "The web URL of the Git repository"
  value       = azuredevops_git_repository.infra.web_url
}

output "repository_app_id" {
  description = "The ID of the Git repository"
  value       = data.azuredevops_git_repository.app.id
}

output "repository_app_name" {
  description = "The name of the Git repository"
  value       = data.azuredevops_git_repository.app.name
}

output "repository_app_url" {
  description = "The clone URL of the Git repository"
  value       = data.azuredevops_git_repository.app.remote_url
}

output "repository_app_web_url" {
  description = "The web URL of the Git repository"
  value       = data.azuredevops_git_repository.app.web_url
}

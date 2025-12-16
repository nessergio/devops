# Get Azure DevOps agent pool ID
data "azuredevops_agent_queue" "default" {
  project_id  = azuredevops_project.project.id
  name = "Default"
}

# Authorize agent pool for the pipeline
resource "azuredevops_pipeline_authorization" "agent_pool_auth" {
  project_id  = azuredevops_project.project.id
  resource_id = data.azuredevops_agent_queue.default.id
  type        = "queue"
}

# Azure DevOps environment for production deployments
resource "azuredevops_environment" "prod" {
  project_id = azuredevops_project.project.id
  name       = "production" # Assumes your environment is named 'production'
}

# Authorize deployment to production environment
resource "azuredevops_pipeline_authorization" "env_auth" {
  project_id  = azuredevops_project.project.id
  resource_id = azuredevops_environment.prod.id
  type        = "environment"
}





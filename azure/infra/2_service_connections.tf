# Get current Azure subscription and tenant information
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Azure DevOps service connection for ACR Docker registry operations
resource "azuredevops_serviceendpoint_azurecr" "acr_sc" {
  project_id            = var.project_id
  service_endpoint_name = "acr-rbac-connection"
  resource_group        = var.resource_group_name
  description           = "Service connection for ACR using ARM"
  azurecr_name          = var.acr_name

  azurecr_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurecr_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurecr_subscription_name = data.azurerm_subscription.current.display_name
}

# Allow the connection for pipeline use
resource "azuredevops_pipeline_authorization" "acr_sc_auth" {
  project_id  = var.project_id
  resource_id = azuredevops_serviceendpoint_azurecr.acr_sc.id
  type        = "endpoint"
}

# Azure DevOps service connection for Kubernetes deployments to AKS
resource "azuredevops_serviceendpoint_kubernetes" "kubernetes_sc" {
  project_id            = var.project_id
  service_endpoint_name = "kubernetes-rbac-connection"
  description           = "Kubernetes service connection for AKS cluster"

  apiserver_url         = azurerm_kubernetes_cluster.aks.kube_config[0].host
  authorization_type    = "AzureSubscription"

  azure_subscription {
    subscription_id   = data.azurerm_subscription.current.subscription_id
    subscription_name = data.azurerm_subscription.current.display_name
    tenant_id         = data.azurerm_client_config.current.tenant_id
    resourcegroup_id  = azurerm_resource_group.acr.name
    namespace         = "default"
    cluster_name      = azurerm_kubernetes_cluster.aks.name
  }
}

# Allow the Kubernetes connection for pipeline use
resource "azuredevops_pipeline_authorization" "kubernetes_sc_auth" {
  project_id  = var.project_id
  resource_id = azuredevops_serviceendpoint_kubernetes.kubernetes_sc.id
  type        = "endpoint"
}



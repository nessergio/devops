# Get current Azure subscription and tenant information
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Create Azure AD Application for Service Principal
resource "azuread_application" "azdevops_service_connection" {
  display_name = "azdevops-${var.azure_devops_project}-service-connection"
}

# Create Service Principal
resource "azuread_service_principal" "azdevops_service_connection" {
  client_id = azuread_application.azdevops_service_connection.client_id
}

# Create Service Principal Password
resource "azuread_service_principal_password" "azdevops_service_connection" {
  service_principal_id = azuread_service_principal.azdevops_service_connection.object_id
  end_date_relative    = "17520h" # 2 years
}

# Assign Contributor role to Service Principal on the subscription
resource "azurerm_role_assignment" "azdevops_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.azdevops_service_connection.object_id
}

# Assign User Access Administrator to Service Principal on the subscription
resource "azurerm_role_assignment" "azdevops_uaa" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.azdevops_service_connection.object_id
}

# Create Azure DevOps Service Endpoint (Service Connection)
resource "azuredevops_serviceendpoint_azurerm" "azure_connection" {
  project_id                             = module.project.project_id
  service_endpoint_name                  = "Azure-ServiceConnection"
  description                            = "Azure service connection for ${var.azure_devops_project}"
  service_endpoint_authentication_scheme = "ServicePrincipal"

  credentials {
    serviceprincipalid  = azuread_application.azdevops_service_connection.client_id
    serviceprincipalkey = azuread_service_principal_password.azdevops_service_connection.value
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name

  depends_on = [
    azuread_service_principal.azdevops_service_connection,
    azuread_service_principal_password.azdevops_service_connection,
    azurerm_role_assignment.azdevops_contributor
  ]
}




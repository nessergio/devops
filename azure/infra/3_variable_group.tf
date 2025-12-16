# Azure DevOps variable group containing infrastructure outputs for app pipeline
resource "azuredevops_variable_group" "infra_vars" {
  project_id   = var.project_id
  name         = "Infrastructure-Vars"
  allow_access = true

  variable {
    name       = "HOST"
    value      = azurerm_public_ip.ingress.fqdn
  }

  variable {
    name       = "ACR"
    value      = "${var.acr_name}.azurecr.io"
  }
}

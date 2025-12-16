# Resource group for infrastructure resources (ACR, AKS, networking)
resource "azurerm_resource_group" "acr" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Azure Container Registry for storing Docker images
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location
  sku                 = var.acr_sku
  admin_enabled       = true  # Enable admin for ArgoCD Image Updater

  tags = var.tags
}


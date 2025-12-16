# Generate random suffix for globally unique storage account name
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource group for bootstrap resources including state storage
resource "azurerm_resource_group" "bootstrap" {
  name     = var.resource_group_name
  location = var.location
}

# Storage account for storing Terraform state with versioning enabled
resource "azurerm_storage_account" "tfstate" {
  name                     = "${var.storage_account_prefix}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.bootstrap.name
  location                 = azurerm_resource_group.bootstrap.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    environment = "bootstrap"
    purpose     = "terraform-state"
  }
}

# Blob container for storing Terraform state files
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

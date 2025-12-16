output "resource_group_name" {
  description = "Name of the resource group containing the storage account"
  value       = azurerm_resource_group.bootstrap.name
}

output "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the blob container for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format for backend.tf file"
  value = {
    resource_group_name  = azurerm_resource_group.bootstrap.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "${var.azure_devops_project}.tfstate"
  }
}

output "azure_devops_project_id" {
  description = "Azure DevOps project ID"
  value       = module.project.project_id
}

output "azure_devops_project_name" {
  description = "Azure DevOps project name"
  value       = module.project.project_name
}

output "service_principal_client_id" {
  description = "Client ID of the service principal for Azure DevOps"
  value       = azuread_application.azdevops_service_connection.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal for Azure DevOps"
  value       = azuread_service_principal.azdevops_service_connection.object_id
}

output "service_principal_client_secret" {
  description = "Client secret of the service principal (sensitive)"
  value       = azuread_service_principal_password.azdevops_service_connection.value
  sensitive   = true
}

output "azure_service_connection_id" {
  description = "ID of the Azure DevOps service connection"
  value       = azuredevops_serviceendpoint_azurerm.azure_connection.id
}

output "azure_service_connection_name" {
  description = "Name of the Azure DevOps service connection"
  value       = azuredevops_serviceendpoint_azurerm.azure_connection.service_endpoint_name
}

output "azure_subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "azure_tenant_id" {
  description = "Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "build_agent_vm_name" {
  description = "Name of the build agent VM"
  value       = azurerm_linux_virtual_machine.agent_vm.name
}

output "build_agent_vm_public_ip" {
  description = "Public IP address of the build agent VM"
  value       = azurerm_public_ip.agent_pip.ip_address
}

output "build_agent_ssh_private_key_path" {
  description = "Path to the SSH private key for the build agent VM"
  value       = local_file.agent_ssh_private_key.filename
}

output "build_agent_ssh_command" {
  description = "SSH command to connect to the build agent VM"
  value       = "ssh -i ${local_file.agent_ssh_private_key.filename} ${var.agent_vm_admin_username}@${azurerm_public_ip.agent_pip.ip_address}"
}

output "build_agent_pool" {
  description = "Azure DevOps agent pool where the agent is registered"
  value       = "Default"
}


variable "azure_devops_org_url" {
  type        = string
  description = "Azure DevOps organization URL"
}

variable "azure_devops_pat" {
  type = string
  #sensitive   = true
  description = "Azure DevOps Personal Access Token"
}

variable "azure_devops_project" {
  type        = string
  default     = "TestProject"
  description = "Azure DevOps project name"
}

variable "azure_devops_project_description_infra" {
  type        = string
  default     = "Project for infrastructure as code demonstration."
  description = "Azure DevOps project description"
}

variable "azure_devops_project_description_app" {
  type        = string
  default     = "Hello test application - web app deployed to AKS"
  description = "Azure DevOps project description for application"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-bootstrap"
  description = "Name of the resource group for bootstrap resources (state storage, build agent, etc.)"
}

variable "location" {
  type        = string
  default     = "chilecentral"
  description = "Azure region for resources"
}

variable "storage_account_prefix" {
  type        = string
  default     = "tfstate"
  description = "Prefix for storage account name (will be appended with random suffix)"
}

variable "container_name" {
  type        = string
  default     = "tfstate"
  description = "Name of the blob container for Terraform state files"
}

variable "agent_vm_name" {
  type        = string
  default     = "vm-build-agent"
  description = "Name of the build agent virtual machine"
}

variable "agent_vm_size" {
  type        = string
  default     = "Standard_B2ats_v2"
  description = "Size of the build agent VM"
}

variable "agent_vm_admin_username" {
  type        = string
  default     = "azureuser"
  description = "Admin username for the build agent VM"
}

variable "force_push" {
  type        = bool
  description = "Force push on every terraform apply (uses timestamp trigger)"
  default     = false
}



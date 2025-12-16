variable "azdo_pat" {
  type      = string
  sensitive = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "acr-rg"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  type        = string
}

variable "acr_sku" {
  description = "SKU tier for the Azure Container Registry (Basic, Standard, or Premium)"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The acr_sku must be Basic, Standard, or Premium."
  }
}

variable "project_id" {
  description = "ID of the project of the app"
  type        = string
  default     = null
}

variable "admin_enabled" {
  description = "Enable admin user for the Azure Container Registry"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# AKS Variables
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "system_node_count" {
  description = "Initial number of nodes in the system node pool"
  type        = number
  default     = 2
}

variable "system_node_min_count" {
  description = "Minimum number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum number of nodes in the system node pool"
  type        = number
  default     = 5
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

# Ingress Variables
variable "ingress_domain_label" {
  description = "Domain label for the ingress public IP (will be <label>.<region>.cloudapp.azure.com)"
  type        = string
}

# Let's Encrypt Variables
variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "argocd_admin_pass" {
  description = "Argo CD admin password"
  type        = string
  sensitive   = true
}

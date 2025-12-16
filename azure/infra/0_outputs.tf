output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The admin username for the Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "The admin password for the Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.acr.name
}

# AKS Outputs
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_node_resource_group" {
  description = "The name of the AKS node resource group"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

# Ingress Outputs
output "ingress_public_ip" {
  description = "The public IP address of the ingress controller"
  value       = azurerm_public_ip.ingress.ip_address
}

output "ingress_fqdn" {
  description = "The FQDN for the ingress controller (with Let's Encrypt certificate)"
  value       = azurerm_public_ip.ingress.fqdn
}

output "ingress_domain_label" {
  description = "The domain label for the ingress public IP"
  value       = azurerm_public_ip.ingress.domain_name_label
}

# Certificate Outputs
output "letsencrypt_cluster_issuer" {
  description = "The name of the Let's Encrypt ClusterIssuer (production)"
  value       = "letsencrypt-prod"
}

output "letsencrypt_staging_issuer" {
  description = "The name of the Let's Encrypt ClusterIssuer (staging)"
  value       = "letsencrypt-staging"
}

output "default_certificate_secret" {
  description = "The name of the default TLS certificate secret"
  value       = "default-tls-certificate"
}

# Instructions
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.acr.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "ingress_url" {
  description = "The HTTPS URL for the ingress (ready for use with Let's Encrypt certificate)"
  value       = "https://${azurerm_public_ip.ingress.fqdn}"
}


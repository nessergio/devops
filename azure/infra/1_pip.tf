# Get AKS node resource group name
data "azurerm_resource_group" "aks_node_rg" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Public IP for Ingress
resource "azurerm_public_ip" "ingress" {
  name                = "${var.aks_cluster_name}-ingress-ip"
  location            = azurerm_resource_group.acr.location
  resource_group_name = data.azurerm_resource_group.aks_node_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.ingress_domain_label

  tags = var.tags

  depends_on = [azurerm_kubernetes_cluster.aks]
}



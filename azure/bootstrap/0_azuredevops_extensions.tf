# Install Terraform extension from Azure DevOps Marketplace automatically
# Uses REST API to install the extension in the organization

resource "null_resource" "install_azdo_extensions" {
  provisioner "local-exec" {
    command = <<-EOT
      az extension add --name azure-devops
      az devops extension install --extension-id custom-terraform-tasks --publisher-id ms-devlabs --org ${var.azure_devops_org_url} || echo "Azure CLI DevOps extension already installed"
    EOT

    environment = {
      AZURE_DEVOPS_PAT     = var.azure_devops_pat
      AZURE_DEVOPS_ORG_URL = var.azure_devops_org_url
    }
  }
}

output "azdo_extension_info" {
  description = "Information about installed Azure Devops extension"
  value = {
    publisher_id    = "ms-devlabs"
    extension_id    = "custom-terraform-tasks"
    marketplace_url = "https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks"
    tasks_available = [
      "TerraformInstaller@0 - Install specific Terraform version",
      "TerraformTaskV4@4 - Execute Terraform commands"
    ]
  }
}

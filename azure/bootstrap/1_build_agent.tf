# Azure DevOps Build Agent VM
# Creates a Linux VM and installs Azure Pipelines agent

# Virtual Network for the agent
resource "azurerm_virtual_network" "agent_vnet" {
  name                = "vnet-build-agent"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name

  tags = {
    environment = "bootstrap"
    purpose     = "build-agent"
  }
}

# Subnet for the build agent VM
resource "azurerm_subnet" "agent_subnet" {
  name                 = "subnet-build-agent"
  resource_group_name  = azurerm_resource_group.bootstrap.name
  virtual_network_name = azurerm_virtual_network.agent_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for the VM (optional, for SSH access)
resource "azurerm_public_ip" "agent_pip" {
  name                = "pip-build-agent"
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "bootstrap"
    purpose     = "build-agent"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "agent_nsg" {
  name                = "nsg-build-agent"
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "bootstrap"
    purpose     = "build-agent"
  }
}

# Network Interface
resource "azurerm_network_interface" "agent_nic" {
  name                = "nic-build-agent"
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.agent_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_pip.id
  }

  tags = {
    environment = "bootstrap"
    purpose     = "build-agent"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "agent_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.agent_nic.id
  network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

# Generate SSH key for VM access
resource "tls_private_key" "agent_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save SSH private key locally
resource "local_file" "agent_ssh_private_key" {
  content         = tls_private_key.agent_ssh.private_key_pem
  filename        = "${path.module}/agent_ssh_key.pem"
  file_permission = "0600"
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                = var.agent_vm_name
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  size                = var.agent_vm_size
  admin_username      = var.agent_vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.agent_nic.id,
  ]

  admin_ssh_key {
    username   = var.agent_vm_admin_username
    public_key = tls_private_key.agent_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "bootstrap"
    purpose     = "build-agent"
  }
}

# Get Azure DevOps agent pool ID
data "azuredevops_agent_pool" "default" {
  name = "Default"
}

# Install and configure Azure Pipelines agent
resource "null_resource" "install_azure_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.agent_vm,
    module.project
  ]

  triggers = {
    vm_id      = azurerm_linux_virtual_machine.agent_vm.id
    project_id = module.project.project_id
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.agent_pip.ip_address
    user        = var.agent_vm_admin_username
    private_key = tls_private_key.agent_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",

      # Check if agent is already configured and running
      "echo 'Checking if Azure Pipelines agent is already installed...'",
      "if [ -f ~/agent/config.sh ] && [ -f ~/agent/.agent ]; then",
      "  echo 'Agent configuration found, checking if service is running...'",
      "  if sudo systemctl is-active --quiet vsts.agent.*.*.service 2>/dev/null || pgrep -f 'Agent.Listener' >/dev/null 2>&1; then",
      "    echo 'Azure Pipelines agent is already configured and running!'",
      "    echo 'Skipping installation.'",
      "    exit 0",
      "  else",
      "    echo 'Agent configured but not running, will reconfigure...'",
      "  fi",
      "fi",

      "echo 'Starting fresh agent installation...'",
      "echo 'Updating system packages...'",
      "sudo apt-get update",
      "sudo apt-get install -y curl jq apt-transport-https ca-certificates unzip software-properties-common",

      # Install Docker
      "echo 'Installing Docker...'",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ${var.agent_vm_admin_username}",

      # Create agent directory
      "echo 'Setting up Azure Pipelines agent...'",
      "mkdir -p ~/agent",
      "cd ~/agent",

      # Download and extract agent
      "AGENT_VERSION=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq -r '.tag_name' | sed 's/v//')",
      "echo \"Downloading agent version: $AGENT_VERSION\"",
      "curl -LO https://download.agent.dev.azure.com/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz",
      "tar xzf vsts-agent-linux-x64-$AGENT_VERSION.tar.gz",

      # Configure agent
      "echo 'Configuring agent...'",
      "sudo ./bin/installdependencies.sh",
      "./config.sh --unattended --url '${var.azure_devops_org_url}' --auth pat --token '${var.azure_devops_pat}' --pool 'Default' --agent '${var.agent_vm_name}' --acceptTeeEula --replace",

      # Install and start agent service
      "echo 'Installing agent as service...'",
      "sudo ./svc.sh install ${var.agent_vm_admin_username}",
      "sudo ./svc.sh start",

      # Verify agent is running
      "echo 'Verifying agent status...'",
      "sudo ./svc.sh status",

      "echo 'Azure Pipelines agent installation complete!'"
    ]
  }
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}
resource "azurerm_virtual_network" "vnet" {
  name                = "TFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "TFSubnet" {
  for_each             = var.vnet
  name                 = each.key
  address_prefixes     = [each.value.subnet_address]
  virtual_network_name = "TFVnet"
  resource_group_name  = azurerm_resource_group.rg.name
}
# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic_fe01" {
  name                = "NICfe01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "NICfe01-cfg"
    subnet_id                     = azurerm_subnet.TFSubnet["subnetfe01"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic_be01" {
  name                = "NICbe01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "NICbe01-cfg"
    subnet_id                     = azurerm_subnet.TFSubnet["subnetbe01"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic_be02" {
  name                = "NICbe02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "NICbe02-cfg"
    subnet_id                     = azurerm_subnet.TFSubnet["subnetbe01"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic_be03" {
  name                = "NICbe03"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "NICbe03-cfg"
    subnet_id                     = azurerm_subnet.TFSubnet["subnetbe01"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic_fe01.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}
resource "random_id" "random_id" {
  for_each = var.vm
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8

}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  for_each                 = var.vm
  name                     = "diag${random_id.random_id[each.key].hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "local_file" "cloud_pem" { 
  filename = "${path.module}/../tls_private_key.pem"
  content = tls_private_key.example_ssh.private_key_pem
}
locals {
  nics = {
    "VMLUE01" = [azurerm_network_interface.my_terraform_nic_fe01.id, azurerm_network_interface.my_terraform_nic_be01.id],
    "VMLU01"  = [azurerm_network_interface.my_terraform_nic_be02.id],
    "VMLU02"  = [azurerm_network_interface.my_terraform_nic_be03.id],
  }
}
# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  for_each            = var.vm
  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  #network_interface_ids = each.value.nics
  network_interface_ids = local.nics[each.key]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk${random_id.random_id[each.key].hex}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = each.key
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account[each.key].primary_blob_endpoint
  }
}

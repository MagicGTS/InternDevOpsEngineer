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
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
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
  account_replication_type = "ZRS"
}

locals {
  nics = {
    "VMWSRV2016" = [azurerm_network_interface.my_terraform_nic_fe01.id]
  }
}
# Create Windows Server
resource "azurerm_windows_virtual_machine" "windows-vm" {
  for_each            = var.vm
  name                  = "windows-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.windows_vm_size
  network_interface_ids = [azurerm_network_interface.windows-vm-nic.id]
  
  computer_name  = "windows-vm"
  admin_username = var.windows_admin_username
  admin_password = var.windows_admin_password
  os_disk {
    name                 = "windows-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows_2022_sku
    version   = "latest"
  }
  enable_automatic_updates = true
  provision_vm_agent       = true
}
# Create virtual machine
resource "azurerm_windows_virtual_machine" "my_terraform_vm" {
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

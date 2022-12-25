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
    subnet_id                     = azurerm_subnet.TFSubnet["subnet01"].id
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

# Create a Storage account
resource "azurerm_storage_account" "terraform_storage_account" {
  for_each                 = var.vm
  name                     = "cs${random_id.random_id[each.key].hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  access_tier              = "Cool"
}
resource "azurerm_storage_container" "terraform_storage_container" {
  for_each              = var.vm
  name                  = "${var.container_name}${random_id.random_id[each.key].hex}"
  storage_account_name  = azurerm_storage_account.terraform_storage_account[each.key].name
  container_access_type = "private"
}
resource "azurerm_storage_blob" "terraform_blob_storage" {
  for_each               = var.vm
  name                   = "${var.container_name}${random_id.random_id[each.key].hex}"
  storage_account_name   = azurerm_storage_account.terraform_storage_account[each.key].name
  storage_container_name = azurerm_storage_container.terraform_storage_container[each.key].name
  type                   = "Block"
}
resource "azurerm_storage_share" "terraform_blob_share" {
  for_each             = var.vm
  name                 = "${var.container_name}${random_id.random_id[each.key].hex}"
  storage_account_name = azurerm_storage_account.terraform_storage_account[each.key].name

  acl {
    id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"

    access_policy {
      permissions = "rwdl"
      start       = "2022-12-24T09:38:21.0000000Z"
      expiry      = "2023-12-24T10:38:21.0000000Z"
    }
  }
  enabled_protocol = "SMB"
  quota            = 10
}
locals {
  nics = {
    "VMWSRV2016" = [azurerm_network_interface.my_terraform_nic_fe01.id]
  }
}
# Create Windows Server
resource "azurerm_windows_virtual_machine" "windows-vm" {
  for_each              = var.vm
  name                  = "windows-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  network_interface_ids = local.nics["VMWSRV2016"]

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
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  enable_automatic_updates = true
  provision_vm_agent       = true
}
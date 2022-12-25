output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_addresses" {
  value = [
    for key, value in azurerm_windows_virtual_machine.windows-vm : { "vm" : key, "ip" : value.public_ip_addresses } if lookup(value, "public_ip_addresses", null) != null
  ]

}

output "private_ip_addressses" {
  value = [
    for key, value in azurerm_windows_virtual_machine.windows-vm : { "vm" : key, "ip" : value.private_ip_addresses } if lookup(value, "private_ip_addresses", null) != null
  ]

}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
/*
output "public_ip_addresses" {
  value = [
    for key, value in azurerm_linux_virtual_machine.my_terraform_vm : { "vm" : key, "ip" : value.public_ip_addresses } if lookup(value, "public_ip_addresses", null) != null
  ]

}

output "private_ip_addressses" {
  value = [
    for key, value in azurerm_linux_virtual_machine.my_terraform_vm : { "vm" : key, "ip" : value.private_ip_addresses } if lookup(value, "private_ip_addresses", null) != null
  ]

}
 
output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}
 */
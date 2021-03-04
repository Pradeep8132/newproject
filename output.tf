output "random_password" {
  value = random_password.password.result
}

output "public_ip" {
  value = azurerm_public_ip.avpip.*.ip_address
}

output "virtual_machine" {
  value = azurerm_virtual_machine.virtualmachines.*.name
}
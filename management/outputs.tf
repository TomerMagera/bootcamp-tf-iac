output "controller_admin_password" {
  value     = azurerm_linux_virtual_machine.controllervm.admin_password
  sensitive = true
}

output "controller_public_ip_addr" {
  description = "id of the public ip address provisoned."
  value       = azurerm_linux_virtual_machine.controllervm.public_ip_address
}

output "controller_private_ip_addr" {
  value = azurerm_linux_virtual_machine.controllervm.private_ip_address
}

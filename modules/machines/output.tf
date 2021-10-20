output "vm_admin_password" {
  value = azurerm_linux_virtual_machine.vm.admin_password
}

output "network_interface_ids" {
  description = "ids of the vm nics provisoned."
  value       = azurerm_network_interface.ni.id
}

output "network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = azurerm_network_interface.ni.private_ip_address
}



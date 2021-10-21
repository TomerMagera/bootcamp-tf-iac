
output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "subnets_names" {
  value = [
    for subnet in flatten(azurerm_subnet.subnets) :
    subnet.name
  ]
}

output "subnets_ids" {
  value = [
    for subnet in flatten(azurerm_subnet.subnets) :
    subnet.id
  ]
}

output "pg_admin_password" {
  value     = azurerm_postgresql_server.postgress_db.administrator_login_password
  sensitive = true
}

output "pg_admin_username" {
  value     = azurerm_postgresql_server.postgress_db.administrator_login
  sensitive = true
}

output "public_ip_addr" {
  description = "id of the public ip address provisoned."
  value       = azurerm_public_ip.pip.*.ip_address
}

output "vmss_id" {
  description = "vm ss id"
  value       = azurerm_linux_virtual_machine_scale_set.linuxvmss.id
}

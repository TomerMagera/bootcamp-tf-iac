
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

output "ws_admin_password" {
  value = [
    for server in flatten(module.webservers) :
    server.vm_admin_password
  ]
  sensitive = true
}

output "dbs_admin_password" {
  value = [
    for server in flatten(module.dbserver) :
    server.vm_admin_password
  ]
  sensitive = true
}

output "count_of_webservers" {
  value = length(module.webservers)
}

output "public_ip_addr" {
  description = "id of the public ip address provisoned."
  value       = azurerm_public_ip.pip.*.ip_address
}


output "dbserver_internal_ip" {
  value = [
    for server in flatten(module.dbserver) :
    server.network_interface_private_ip
  ]
}

output "webservers_internal_ip" {
  value = [
    for server in flatten(module.webservers) :
    server.network_interface_private_ip
  ]
}

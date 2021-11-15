
resource "azurerm_postgresql_server" "postgress_db" {
  name                          = "${local.name_prefix}-postgres-db-server"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  administrator_login           = var.db_admin_user
  administrator_login_password  = var.db_admin_pass
  backup_retention_days         = 7
  sku_name                      = "B_Gen5_1"
  version                       = "11"
  geo_redundant_backup_enabled  = false
  auto_grow_enabled             = true
  public_network_access_enabled = true
  ssl_enforcement_enabled       = false


}

# azure postgresql firewall rules - public ip
resource "azurerm_postgresql_firewall_rule" "pg_fw_rule_pip" {
  name                = "allow-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.postgress_db.name
  start_ip_address    = azurerm_public_ip.pip.ip_address
  end_ip_address      = azurerm_public_ip.pip.ip_address
}

data "azurerm_virtual_network" "staging_vnet" {
  name                = var.staging_vnet
  resource_group_name = var.staging_rg_name
}

data "azurerm_virtual_network" "production_vnet" {
  name                = var.production_vnet
  resource_group_name = var.production_rg_name
}

resource "azurerm_virtual_network_peering" "ansible_staging_peering" {
  name                      = var.peering_name_staging
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.staging_vnet.id
}

resource "azurerm_virtual_network_peering" "connect_ansible_staging_peering" {
  name                      = var.peering_name_staging
  resource_group_name       = var.staging_rg_name
  virtual_network_name      = var.staging_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

resource "azurerm_virtual_network_peering" "ansible_production_peering" {
  name                      = var.peering_name_production
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.production_vnet.id
}

resource "azurerm_virtual_network_peering" "connect_ansible_production_peering" {
  name                      = var.peering_name_production
  resource_group_name       = var.production_rg_name
  virtual_network_name      = var.production_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

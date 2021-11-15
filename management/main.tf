# Configure the Azure provider
# the resource group that will contain all the resources
# which we need to build the project infrastructure
resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-${var.resource_group_name}"
  location = var.resource_group_location
  tags     = var.tags
}

# create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-${var.vnet_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  depends_on = [azurerm_resource_group.rg]
}

# will create 2 subnets: public & private
resource "azurerm_subnet" "subnets" {
  count                = length(var.subnets_cidrs)
  name                 = "${local.name_prefix}-${element(var.subnets_names, count.index)}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [element(var.subnets_cidrs, count.index)]

  depends_on = [azurerm_virtual_network.vnet]
}


# The NSGs - pubic and private.
resource "azurerm_network_security_group" "nsgs" {
  count               = length(var.nsgs)
  name                = "${local.name_prefix}-${element(var.nsgs, count.index)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

# connect between the NSGs and their respective subnets.
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_asc" {
  count                     = length(var.subnets_names)
  subnet_id                 = element(azurerm_subnet.subnets.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.nsgs.*.id, count.index)
}

## creating inbound rules for the public/web nsg.
## ports 8080 and 22
resource "azurerm_network_security_rule" "public_nsg_rule_inbound" {
  for_each                    = local.public_nsg_inbound_ports_map
  name                        = "Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsgs[0].name
  resource_group_name         = azurerm_resource_group.rg.name

  depends_on = [azurerm_network_security_group.nsgs]
}




# 1. seperate variables' values to .tfvar file. - done
# 2. add postgres module handling.
# 3. Add things for LB: LBRule, LBRule1, health probes.
# 4. handle the backend part.
# 5. handle the NSG rules - ports 8080,22,5432 - done
# 6. add admin user/pass as arguments to module webserves for vm authentication - done


# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # --> by default it's - "registry.terraform.io/hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# local variables/values
locals {
  name_prefix = var.environment
  # priorities/ports for inbound security rules of the public NSG
  public_nsg_inbound_ports_map = {
    "1000" : "8080",
    "1010" : "22"
  }
  # priorities/ports for inbound security rules of the private NSG
  private_nsg_inbound_ports_map = {
    "1000" : "5432",
    "1010" : "22"
  }
}

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

# create the public ip - will be ascociated to the load balancer
resource "azurerm_public_ip" "pip" {
  name                = "${local.name_prefix}-${var.public_ip_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

# create the load balancer
resource "azurerm_lb" "lb" {
  name                = "${local.name_prefix}-${var.lb_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${local.name_prefix}-publicIPAddress-0"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  tags       = var.tags
  depends_on = [azurerm_public_ip.pip]
}

# create load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool-addrs"

  depends_on = [azurerm_lb.lb]
}

# create LB probe - will be used for the LB rules.
resource "azurerm_lb_probe" "lb_probe" {
  name                = "tcp-probe"
  protocol            = "Tcp"
  port                = 8080
  loadbalancer_id     = azurerm_lb.lb.id
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_lb.lb]
}

resource "azurerm_lb_probe" "lb_probe1" {
  name                = "ssh-probe"
  protocol            = "Tcp"
  port                = 22
  loadbalancer_id     = azurerm_lb.lb.id
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_lb.lb]
}

# create load balancer rule - pass traffic coming on p8080 to web vms p8080
resource "azurerm_lb_rule" "lb_rule_1" {
  name                           = "lb-rule-1"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.lb_probe.id
  loadbalancer_id                = azurerm_lb.lb.id
  resource_group_name            = azurerm_resource_group.rg.name

  depends_on = [azurerm_lb_probe.lb_probe]
}

resource "azurerm_lb_rule" "lb_rule_2" {
  name                           = "lb-rule-2"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.lb_probe1.id
  loadbalancer_id                = azurerm_lb.lb.id
  resource_group_name            = azurerm_resource_group.rg.name

  depends_on = [azurerm_lb_probe.lb_probe1]
}

# configuring lb backend pool with the webservers 
# that the LB will need to balance load to them.
resource "azurerm_lb_backend_address_pool_address" "be_addrpool_addr" {
  count                   = length(module.webservers)
  name                    = "${local.name_prefix}-addr_pool_addr-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  virtual_network_id      = azurerm_virtual_network.vnet.id
  ip_address              = element(module.webservers.*.network_interface_private_ip, count.index)

  depends_on = [module.webservers]
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

## creating inbound rules for the private/db nsg.
## ports 5432 and 22
resource "azurerm_network_security_rule" "private_nsg_rule_inbound" {
  for_each                    = local.private_nsg_inbound_ports_map
  name                        = "Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsgs[1].name
  resource_group_name         = azurerm_resource_group.rg.name

  depends_on = [azurerm_network_security_group.nsgs]
}

resource "azurerm_availability_set" "avset" {
  name                         = "${local.name_prefix}-avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

# create storage account
resource "azurerm_storage_account" "storage" {
  name                     = "tomerbcstorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

# create storage container
resource "azurerm_storage_container" "storagecont" {
  name                  = "bootcamp-storage-container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.storage]
}


# Creating the web VMs and their NICs
module "webservers" {
  source = "./modules/machines"

  count               = var.num_webservers_to_create
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnets[0].id
  vm_name             = "webserver-${count.index}"
  avset_id            = azurerm_availability_set.avset.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  tags = var.tags
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_availability_set.avset
  ]
}

# Creating the db VM and its NIC
module "dbserver" {
  source = "./modules/machines"

  count               = 1
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnets[1].id
  vm_name             = "dbserver"
  avset_id            = azurerm_availability_set.avset.id
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_availability_set.avset,
    module.webservers
  ]
}

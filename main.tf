

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # --> by default it's - "registry.terraform.io/hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
/*
  # terraform state storage to Azure storage container
  # will store the state of the bonus b entire infrastructure.
  backend "azurerm" {
    resource_group_name  = "devEnv-rg-bootcamp-tf"
    storage_account_name = "tomerbcstorageaccount"
    container_name       = "bootcamp-storage-container"
    key                  = "week5-bonus-c-terraform.tfstate"
  }
*/
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

resource "azurerm_network_security_rule" "private_nsg_rule_outbound" {
  name                        = "DenyInternet"
  priority                    = "1000"
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsgs[1].name

  depends_on = [azurerm_network_security_group.nsgs]
}

# the azure postgresql server - managed db service.
resource "azurerm_postgresql_server" "postgress_db" {
  name                          = "${local.name_prefix}-postgres-db-server"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  backup_retention_days         = 7
  sku_name                      = "GP_Gen5_4"
  version                       = "11"
  geo_redundant_backup_enabled  = true
  auto_grow_enabled             = true
  public_network_access_enabled = true
  ssl_enforcement_enabled       = false

  tags = var.tags
}

# azure postgresql firewall rules - public ip
resource "azurerm_postgresql_firewall_rule" "pg_fw_rule_pip" {
  name                = "allow-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.postgress_db.name
  start_ip_address    = azurerm_public_ip.pip.ip_address
  end_ip_address      = azurerm_public_ip.pip.ip_address
}

# azure linux virtual machine scale set.
resource "azurerm_linux_virtual_machine_scale_set" "linuxvmss" {
  name                = "${local.name_prefix}-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.vm_size
  instances           = 2
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  upgrade_mode = "Automatic"

  network_interface {
    name                      = "vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.nsgs[0].id # public NSG

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnets[0].id # public subnet
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  disable_password_authentication = "false"

  tags = var.tags
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_lb_backend_address_pool.backend_pool,
    azurerm_network_security_group.nsgs,
    azurerm_subnet.subnets
  ]
}

# azure monitor auto scaling setting
# This is instead of the module of the VMs which was creating the 3 webservers.
resource "azurerm_monitor_autoscale_setting" "mon_scalesetting" {
  name                = "${local.name_prefix}-autoscale-setting"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.linuxvmss.id
  # Notification  
  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["tomer.magera@gmail.com"]
    }
  }

  # default profile
  profile {
    name = "defaultprofile"
    # Capacity Block     
    capacity {
      default = 2
      minimum = 2
      maximum = 3
    }

    ## Scale-Out - as per percentage cpu metric - if crossed threshold 85 
    rule {
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linuxvmss.id
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 85
      }
    }

    ## Scale-In - as per percentage cpu metric - if crossed threshold 85
    rule {
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linuxvmss.id
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }
    }
  }

  depends_on = [azurerm_linux_virtual_machine_scale_set.linuxvmss]
}



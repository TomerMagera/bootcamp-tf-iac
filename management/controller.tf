
# create the public ip - will be ascociated to the controller
resource "azurerm_public_ip" "controller-pip" {
  name                = "${local.name_prefix}-${var.controller_public_ipname}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_network_interface" "nic-controller" {
  name                = "controller-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "controller-ip_configuration"
    subnet_id                     = azurerm_subnet.subnets[0].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.controller-pip.id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "controllervm" {
  name     = "${local.name_prefix}-controllervm"
  location = azurerm_resource_group.rg.location
  #  availability_set_id   = var.avset_id
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-controller.id]
  size                  = var.vm_size #default exists
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "OS-disk-controller"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = false

  tags       = var.tags
  depends_on = [azurerm_network_interface.nic-controller]

}

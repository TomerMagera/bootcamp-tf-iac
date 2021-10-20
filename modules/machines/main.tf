
resource "azurerm_network_interface" "ni" {
  name                = "NIC-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testConfiguration-${var.vm_name}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  availability_set_id   = var.avset_id
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.ni.id]
  size                  = var.vm_size #default exists
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "OS-disk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = false

  tags       = var.tags
  depends_on = [azurerm_network_interface.ni]

}

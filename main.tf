provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myresourcegroup" {
  name     = "myresourcegroup"
  location = "eastus"
}

resource "azurerm_virtual_network" "mynetwork" {
  name                = "mynetwork"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  subnet {
    name           = "default"
    address_prefix = "10.0.1.0/24"
  }
}

#Public Azure Ip

resource "azurerm_public_ip" "mypublicip" {
  name                = "mypublicip"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Static"
}

#Network Interface attached to public ip

resource "azurerm_network_interface" "mynetworkinterface" {
  name                = "mynetworkinterface"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  ip_configuration {
    name                          = "mynetworkinterfaceconfig"
    subnet_id                     = azurerm_virtual_network.mynetwork.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

# Instance Vm

resource "azurerm_virtual_machine" "myvm" {
  name                  = "myvm"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myresourcegroup.name
  network_interface_ids = [azurerm_network_interface.mynetworkinterface.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name      = "myvm-osdisk"
    caching   = "ReadWrite"
    disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "myvm"
    admin_username = "adminuser"
    admin_password = "admin"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }
}

# Nginx

provisioner "file" {
  source      = "nginx-install.sh"
  destination = "/home/adminuser/nginx-install.sh"
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /home/adminuser/nginx-install.sh",
    "sudo /home/adminuser/nginx-install.sh"
  ]
}

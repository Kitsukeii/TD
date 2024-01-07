resource "azurerm_public_ip" "webserver_public_ip2" {
   name = "webserver_public_ip2"
   location = "West US"
   resource_group_name = azurerm_resource_group.webserver.name
   allocation_method = "Dynamic"

   tags = {
       environment = "dev"
       costcenter = "it"
   }

   depends_on = [azurerm_resource_group.webserver]
}

resource "azurerm_network_interface" "webserver2" {
   name = "nginx-interface2"
   location = azurerm_resource_group.webserver.location
   resource_group_name = azurerm_resource_group.webserver.name

   ip_configuration {
       name = "internal"
       private_ip_address_allocation = "Static"
       private_ip_address = "10.0.1.25"
       subnet_id = module.network.vnet_subnets[0]
       public_ip_address_id = azurerm_public_ip.webserver_public_ip2.id
   }

   depends_on = [azurerm_resource_group.webserver]
}

resource "azurerm_linux_virtual_machine" "nginx2" {
   size = "Standard_F2"
   name = "nginx-webserver2"
   resource_group_name = azurerm_resource_group.webserver.name
   location = azurerm_resource_group.webserver.location
   custom_data = base64encode(file("init.sh"))
   network_interface_ids = [
       azurerm_network_interface.webserver2.id,
   ]

   source_image_reference {
       publisher = "Canonical"
       offer = "UbuntuServer"
       sku = "18.04-LTS"
       version = "latest"
   }

   computer_name = "nginx"
   admin_username = "adminuser"
   admin_password = "Admin1%"
   disable_password_authentication = false

   os_disk {
       name = "nginxdisk201"
       caching = "ReadWrite"
       storage_account_type = "Standard_LRS"
   }

   tags = {
       environment = "dev"
       costcenter = "it"
   }

   depends_on = [azurerm_resource_group.webserver]
}

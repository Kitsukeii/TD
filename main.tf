terraform {
   required_version = ">= 0.12"
   required_providers {
      azurerm = "~>2.24.0"
   }
}

#provider "azurerm" {
#   subscription_id = var.subscription_id
#   client_id = var.client_id
#   client_secret = var.client_secret
#   tenant_id = var.tenant_id
#   features {}
#}

resource "azurerm_resource_group" "webserver" {
   name = "nginx-server"
   location = "West US"
}

resource "azurerm_network_security_group" "allowedports" {
   name = "allowedports"
   resource_group_name = azurerm_resource_group.webserver.name
   location = azurerm_resource_group.webserver.location
  
   security_rule {
       name = "http"
       priority = 100
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "80"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }

   security_rule {
       name = "https"
       priority = 200
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "443"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }

   security_rule {
       name = "ssh"
       priority = 300
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "22"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }
}

resource "azurerm_public_ip" "webserver_public_ip" {
   name = "webserver_public_ip"
   location = "West US"
   resource_group_name = azurerm_resource_group.webserver.name
   allocation_method = "Dynamic"

   tags = {
       environment = "dev"
       costcenter = "it"
   }

   depends_on = [azurerm_resource_group.webserver]
}

resource "azurerm_network_interface" "webserver" {
   name = "nginx-interface"
   location = azurerm_resource_group.webserver.location
   resource_group_name = azurerm_resource_group.webserver.name

   ip_configuration {
       name = "internal"
       private_ip_address_allocation = "Dynamic"
       subnet_id = module.network.vnet_subnets[0]
       public_ip_address_id = azurerm_public_ip.webserver_public_ip.id
   }

   depends_on = [azurerm_resource_group.webserver]
}

resource "azurerm_linux_virtual_machine" "nginx" {
   size = "Standard_F2"
   name = "nginx-webserver"
   resource_group_name = azurerm_resource_group.webserver.name
   location = azurerm_resource_group.webserver.location
   custom_data = base64encode(file("init.sh"))
   network_interface_ids = [
       azurerm_network_interface.webserver.id,
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
       name = "nginxdisk01"
       caching = "ReadWrite"
       storage_account_type = "Standard_LRS"
   }

   tags = {
       environment = "dev"
       costcenter = "it"
   }

   depends_on = [azurerm_resource_group.webserver]
}
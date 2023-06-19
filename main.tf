# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.41.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.5.1"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_pet" "random" {
  length = 1
}

locals {
  prefix = "${var.prefix}-${random_pet.random.id}"
}

resource "azurerm_resource_group" "myresourcegroup" {
  name     = "${local.prefix}-workshop"
  location = var.location

  tags = {
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix}-vnet"
  location            = azurerm_resource_group.myresourcegroup.location
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.myresourcegroup.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "dogapp_sg" {
  name                = "${local.prefix}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "dogapp_nic" {
  name                = "${local.prefix}-dogapp_nic"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  ip_configuration {
    name                          = "${local.prefix}ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dogapp_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "dogapp_nic_sg_ass" {
  network_interface_id      = azurerm_network_interface.dogapp_nic.id
  network_security_group_id = azurerm_network_security_group.dogapp_sg.id
}

resource "azurerm_public_ip" "dogapp_pip" {
  name                = "${local.prefix}-ip"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.prefix}-woof"
}

data "azurerm_public_ip" "dogapp_pip" {
  name                = azurerm_public_ip.dogapp_pip.name
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_linux_virtual_machine" "dogapp" {
  name                            = "${local.prefix}-woof"
  location                        = azurerm_resource_group.myresourcegroup.location
  resource_group_name             = azurerm_resource_group.myresourcegroup.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.dogapp_nic.id]

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "60"

  }

  tags = {}

  # Added to allow destroy to work correctly.
  depends_on = [azurerm_network_interface_security_group_association.dogapp_nic_sg_ass]
}

# We're using a little trick here so we can run the provisioner without
# destroying the VM. Do not do this in production.

# If you need ongoing management (Day N) of your virtual machines a tool such
# as Chef or Puppet is a better choice. These tools track the state of
# individual files and can keep them in the correct configuration.

# Here we do the following steps:
# Sync everything in files/ to the remote VM.
# Set up some environment variables for our script.
# Add execute permissions to our scripts.
# Run the deploy_app.sh script.
resource "null_resource" "configure_dog_app" {
  depends_on = [
    azurerm_linux_virtual_machine.dogapp,
  ]

  # Terraform 0.11
  # triggers {
  #   build_number = "${timestamp()}"
  # }

  # Terraform 0.12
  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    source      = "files/"
    destination = "/home/${var.admin_username}/"

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.dogapp_pip.fqdn
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt -y update",
      "sudo apt -y install apache2 cowsay",
      "sudo systemctl start apache2",
      "sudo chown -R ${var.admin_username}:${var.admin_username} /var/www/html",
      "cp /home/${var.admin_username}/index.html /var/www/html/index.html",
      "cowsay remote-exec finished"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.dogapp_pip.fqdn
    }
  }
}

check "health_check" {
  data "http" "dogapp" {
    url = "http://${azurerm_public_ip.dogapp_pip.fqdn}"
  }

  assert {
    condition     = data.http.dogapp.status_code == 200
    error_message = "${data.http.dogapp.url} returned an unhealthy status code"
  }
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_names.rg
  location = var.location

  tags = local.common_tags
}

# VNet + Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = var.resource_names.vnet
  address_space       = var.vnet
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

resource "azurerm_subnet" "subnet" {
  name                 = var.resource_names.subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet

  depends_on = [azurerm_virtual_network.vnet]
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = var.resource_names.pip
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# NIC
resource "azurerm_network_interface" "nic" {
  name                = var.resource_names.nic
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  depends_on = [
    azurerm_subnet.subnet,
    azurerm_public_ip.pip,
  ]
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = var.resource_names.nsg
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
  # NOTE: For production, consider restricting source IPs or 
  #using more secure access controls.
  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Postgres
  security_rule {
    name                       = "Postgres"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Keycloak
  security_rule {
    name                       = "Keycloak"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Web (Nginx + OAuth2 Proxy)
  security_rule {
    name                       = "Web"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.resource_names.vm
  computer_name         = var.comp_name                   # Hostname inside the VM
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.vm_username                  # SSH user name
  network_interface_ids = [azurerm_network_interface.nic.id]
  zone                  = "1" 

  depends_on = [azurerm_network_interface_security_group_association.assoc]

  # SSH public key login config
  admin_ssh_key {
    username   = var.vm_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  # OS disk config (no create_option needed)
  os_disk {
    name                 = "${var.resource_names.vm}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.disk
  }

  # Define the OS image to deploy
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = local.common_tags
}
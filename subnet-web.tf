resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.web_subnet_prefix
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.prefix}-web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.allowed_source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_source_cidr
    destination_address_prefix = "*"
  }

  # SSH from Bastion subnet
  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.bastion_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_public_ip" "web_vm" {
  name                = "${var.prefix}-web-vm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "web_vm" {
  name                = "${var.prefix}-web-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_vm.id
  }
}

# VM NSG (Optional in the diagram) attached directly to the NIC
resource "azurerm_network_security_group" "vm" {
  name                = "${var.prefix}-web-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.allowed_source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_source_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.bastion_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "web_vm" {
  network_interface_id      = azurerm_network_interface.web_vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  name                  = "${var.prefix}-web-vm-1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  zone                  = var.availability_zone
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.web_vm.id]
  tags                  = var.tags

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    name                 = "${var.prefix}-web-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Installs nginx so port 80 returns a page
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
      - echo "<h1>Hello from $(hostname) - Web Tier</h1>" > /var/www/html/index.html
  CLOUDINIT
  )
}

# Extra managed data disk (the "Disk" icon in the diagram)
resource "azurerm_managed_disk" "web_vm_data" {
  name                 = "${var.prefix}-web-vm-datadisk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  zone                 = var.availability_zone
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "web_vm_data" {
  managed_disk_id    = azurerm_managed_disk.web_vm_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.web_vm.id
  lun                = 0
  caching            = "ReadWrite"
}

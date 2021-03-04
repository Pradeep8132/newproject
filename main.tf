provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "myfirstgroup" {
  name     = var.resourcegroupname
  location = var.location
  tags     = var.tags
}

resource "azurerm_availability_set" "avset" {
  name                         = var.avsetname
  location                     = azurerm_resource_group.myfirstgroup.location
  resource_group_name          = azurerm_resource_group.myfirstgroup.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}

resource "azurerm_virtual_network" "avnetwork" {
  name                = var.avnetwork
  location            = azurerm_resource_group.myfirstgroup.location
  resource_group_name = azurerm_resource_group.myfirstgroup.name
  address_space       = [element(var.address_space, 0)]
}

resource "azurerm_subnet" "avsubnet" {
  address_prefixes     = [element(var.address_prefixes, 0)]
  name                 = var.avsubnet
  resource_group_name  = azurerm_resource_group.myfirstgroup.name
  virtual_network_name = azurerm_virtual_network.avnetwork.name
}


resource "azurerm_network_security_group" "avnsg" {
  location            = azurerm_resource_group.myfirstgroup.location
  name                = var.avnsg
  resource_group_name = azurerm_resource_group.myfirstgroup.name
  dynamic "security_rule" {
    iterator = rule
    for_each = var.networkrule
    content {
      name                       = rule.value.name
      priority                   = rule.value.priority
      direction                  = rule.value.direction
      access                     = rule.value.access
      protocol                   = rule.value.protocol
      source_port_range          = rule.value.source_port_range
      destination_port_range     = rule.value.destination_port_range
      source_address_prefix      = rule.value.source_address_prefix
      destination_address_prefix = rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "avsubnsg" {
  subnet_id                 = azurerm_subnet.avsubnet.id
  network_security_group_id = azurerm_network_security_group.avnsg.id
}

resource "azurerm_public_ip" "avpip" {
  count               = length(var.vmname)
  name                = var.vmname[count.index]
  location            = azurerm_resource_group.myfirstgroup.location
  resource_group_name = azurerm_resource_group.myfirstgroup.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "avnic" {
  count               = length(var.vmname)
  name                = var.vmname[count.index]
  location            = azurerm_resource_group.myfirstgroup.location
  resource_group_name = azurerm_resource_group.myfirstgroup.name

  ip_configuration {
    name                          = var.vmname[count.index]
    subnet_id                     = azurerm_subnet.avsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.avpip.*.id, count.index)
  }
}

resource "random_password" "password" {
  length  = 8
  special = true
}

resource "azurerm_storage_account" "bootdiagnistic" {
  name                     = "bouosdjlterraform76548"
  resource_group_name      = azurerm_resource_group.myfirstgroup.name
  location                 = azurerm_resource_group.myfirstgroup.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_virtual_machine" "virtualmachines" {
  count               = length(var.vmname)
  name                = var.vmname[count.index]
  availability_set_id = azurerm_availability_set.avset.id
  resource_group_name = azurerm_resource_group.myfirstgroup.name
  location            = azurerm_resource_group.myfirstgroup.location
  boot_diagnostics {
    storage_uri = azurerm_storage_account.bootdiagnistic.primary_blob_endpoint
    enabled     = "true"
  }
  delete_data_disks_on_termination = "true"
  delete_os_disk_on_termination    = "true"
  vm_size                          = "Standard_DS1_v2"
  network_interface_ids            = [element(azurerm_network_interface.avnic.*.id, count.index)]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vmname[count.index]
    admin_username = "testadmin"
    admin_password = random_password.password.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "testadmin"
      password = random_password.password.result
      host     = element(azurerm_public_ip.avpip.*.ip_address, count.index)
    }
    source      = "bash.sh"
    destination = "/home/testadmin/bash.sh"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "testadmin"
      password = random_password.password.result
      host     = element(azurerm_public_ip.avpip.*.ip_address, count.index)
    }
    inline = [
      "ls -a",
      "mkdir thiswascreatedusingtf",
      "chmod +x bash.sh",
      "./bash.sh"
    ]
  }
}
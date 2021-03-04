resourcegroupname = "myfirstgroup"
location          = "uk south"
tags              = { environment = "Prod", owner = "infra" }
avsetname         = "avset"
address_space     = ["10.1.0.0/16", "10.2.0.0/16"]
avnetwork         = "virtualnetwork"
address_prefixes  = ["10.1.1.0/24", "10.1.2.0/24"]
avsubnet          = "avsubnet"
avnsg             = "avnsg"
networkrule = [
  {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "test1234"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "test1235"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
]
vmname = ["one", "two"]


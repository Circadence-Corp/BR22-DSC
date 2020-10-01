resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = join("-", ["vNet", var.name])
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = var.subnets_internal
  subnet_names        = ["subnet"]

  tags = var.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "public_ip" {
  for_each            = var.blueprint
  name                = join("-", ["PublicIP", each.value.hostname])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = var.tags
}

resource "azurerm_storage_account" "sa_netmon" {
  name                     = "netmon"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = var.tags
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.blueprint
  name                = join("-", ["Nic", each.value.hostname])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  ip_configuration {
    name                          = join("-", ["IpConfig", each.value.hostname])
    subnet_id                     = module.vnet.vnet_subnets[0]
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
    private_ip_address            = each.value.private_ip_address
  }
}


#resource "azurerm_network_security_group" "example" {
#  name                = "acceptanceTestSecurityGroup1"
#  location            = azurerm_resource_group.example.location
#  resource_group_name = azurerm_resource_group.example.name
#
#  security_rule {
#    name                       = "test123"
#    priority                   = 100
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "*"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }
#
#  tags = var.tags
#}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = var.blueprint
  name                = each.value.hostname
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = each.value.size
  admin_username      = var.builtinAdministratorAccount
  admin_password      = var.builtinAdministratorPassword
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  os_disk {
    name                 = join("-", ["Disk", each.value.hostname])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.source_image_publisher
    offer     = each.value.source_image_offer
    sku       = each.value.source_image_sku
    version   = each.value.source_image_version
  }

  depends_on = [azurerm_network_interface.nic]
}

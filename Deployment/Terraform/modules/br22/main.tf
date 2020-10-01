resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName
  location = var.location
}

# This is our definition of the machines to create, which the resources will iterate over
variable "blueprint" {
  type = map

  default = {
    "Dc" = {
      hostname               = "ContosoDc",
      private_ip_address     = "10.0.24.4",
      size                   = "Standard_D2s_v3",
      source_image_publisher = "MicrosoftWindowsServer",
      source_image_offer     = "WindowsServer",
      source_image_sku       = "2016-Datacenter",
      source_image_version   = "latest"
    },
    "VictimPc" = {
      hostname               = "VictimPc",
      private_ip_address     = "10.0.24.10",
      size                   = "Standard_D2s_v3",
      source_image_publisher = "MicrosoftWindowsServer",
      source_image_offer     = "WindowsServer",
      source_image_sku       = "2016-Datacenter",
      source_image_version   = "latest"
    },
    "AdminPc" = {
      hostname               = "AdminPc",
      private_ip_address     = "10.0.24.11",
      size                   = "Standard_D2s_v3",
      source_image_publisher = "MicrosoftWindowsServer",
      source_image_offer     = "WindowsServer",
      source_image_sku       = "2016-Datacenter",
      source_image_version   = "latest"
    },
    "Client01" = {
      hostname               = "Client01",
      private_ip_address     = "10.0.24.12",
      size                   = "Standard_D2s_v3",
      source_image_publisher = "MicrosoftWindowsServer",
      source_image_offer     = "WindowsServer",
      source_image_sku       = "2016-Datacenter",
      source_image_version   = "latest"
    }
  }
}


module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = join("-", ["vNet", var.name])
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.24.0/24"]
  subnet_names        = ["subnet"]

  tags = {
    Description = var.description
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "public_ip" {
  for_each            = var.blueprint
  name                = join("-", ["PublicIP", each.value.hostname])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    Description = var.description,
  }
}

resource "azurerm_storage_account" "sa_netmon" {
  name                     = "netmon"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    Description = var.description
  }
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

resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = var.blueprint
  name                = each.value.hostname
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = each.value.size
  admin_username      = var.builtinAdministratorAccount
  admin_password      = var.builtinAdministratorPassword
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id #[for x in azurerm_network_interface.nic[*] : x.id if x.name == join("-", ["Nic", var.blueprint[count.index]["hostname"]])]
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

resource "azurerm_resource_group" "rg" {
  name     = var.ResourceGroupName
  location = var.Location
}

# This is our definition of the machines to create, which the resources will iterate over
variable "blueprint" {
  type = list(object({
    hostname           = string
    private_ip_address = string
  }))

  default = [
    {
      hostname               = "ContosoDc"
      private_ip_address     = "10.0.24.4"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "MicrosoftWindowsServer"
      source_image_offer     = "WindowsServer"
      source_image_sku       = "2016-Datacenter"
      source_image_version   = "latest"
    },
    {
      hostname               = "VictimPc"
      private_ip_address     = "10.0.24.10"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "MicrosoftWindowsServer"
      source_image_offer     = "WindowsServer"
      source_image_sku       = "2016-Datacenter"
      source_image_version   = "latest"
    },
    {
      hostname               = "AdminPc"
      private_ip_address     = "10.0.24.11"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "MicrosoftWindowsServer"
      source_image_offer     = "WindowsServer"
      source_image_sku       = "2016-Datacenter"
      source_image_version   = "latest"
    },
    {
      hostname               = "Client01"
      private_ip_address     = "10.0.24.12"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "MicrosoftWindowsServer"
      source_image_offer     = "WindowsServer"
      source_image_sku       = "2016-Datacenter"
      source_image_version   = "latest"
    }
  ]
}


module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.24.0/24"]
  subnet_names        = ["subnet"]

  tags = {
    Description = var.description
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "public_ip" {
  count               = length(var.blueprint)
  name                = join("PublicIp", each.hostname)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    Description = var.description
  }
}

resource "azurerm_storage_account" "sa" {
  name                     = join(substr(azurerm_resource_group.rg.name, 0, 8), "sa")
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
  count               = length(var.blueprint)
  name                = join("Nic", "-", var.blueprint[count.index][hostname])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  ip_configuration {
    name                          = join("ipconfig", "-", var.blueprint[count.index][hostname])
    subnet_id                     = module.vnet.vnet_subnets[0]
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip[count.index].id
    private_ip_address            = var.blueprint[count.index][hostname]
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  count               = length(var.blueprint)
  name                = var.blueprint[count.index][hostname]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.blueprint[count.index][size]
  admin_username      = var.builtinAdministratorAccount
  admin_password      = var.builtinAdministratorPassword
  network_interface_ids = [
    azurerm_network_interface.nic[join("Nic", "-", var.blueprint[count.index][hostname])].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.blueprint[source_image_publisher]
    offer     = var.blueprint[source_image_offer]
    sku       = var.blueprint[source_image_sku]
    version   = var.blueprint[source_image_version]
  }
}









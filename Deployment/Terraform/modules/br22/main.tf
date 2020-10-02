resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = join("-", ["vNet", var.name])
  address_space       = var.subnets_internal
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

resource "azurerm_network_security_group" "nsg" {
  name                = join("-", ["NSG", var.name])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "inbound_allow_rdp" {
  name                        = "Allow_RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes     = var.mgmt_ips
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
resource "azurerm_network_interface_security_group_association" "nsg_assocation" {
  for_each                  = azurerm_network_interface.nic
  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = var.blueprint
  name                = each.value.hostname
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = each.value.size
  admin_username      = var.creds["builtinAdministratorAccount"]
  admin_password      = var.creds["builtinAdministratorPassword"]
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

data "azurerm_public_ip" "all_public_ips" {
  for_each = azurerm_public_ip.public_ip
  name = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_machine_extension" "dsc_dc" {
  name                 = "dsc_dc"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm["Dc"].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"

  settings = <<SETTINGS
        {
            "configuration": {
                "url": "${var.dsc_info["DcDscUrl"]}",
                "script": "${var.dsc_info["DcDscScript"]}",
                "function": "${var.dsc_info["DcFunction"]}"
              },
            "configurationArguments": {
              "DomainName": "${var.dsc_info["DomainName"]}",
              "UserPrincipalName": "${var.dsc_info["UserPrincipalName"]}",
              "NetBiosName": "${var.dsc_info["NetBiosName"]}",
              "Branch": "${var.dsc_info["Branch"]}"
            }
        }
    SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "configurationArguments": {
        "AdminCreds": {
          "UserName": "${var.creds["builtinAdministratorAccount"]}",
          "Password": "${var.creds["builtinAdministratorPassword"]}"
        },
        "JeffLCreds": {
          "UserName": "JeffL",
          "Password": "${var.creds["JeffLPassword"]}"
        },
        "SamiraACreds": {
          "UserName": "SamiraA",
          "Password": "${var.creds["SamiraAPassword"]}"
        },
        "RonHdCreds": {
          "UserName": "RonHD",
          "Password": "${var.creds["RonHdPassword"]}"
        },
        "LisaVCreds": {
          "UserName": "LisaV",
          "Password": "${var.creds["LisaVPassword"]}"
        },
        "AatpServiceCreds": {
          "UserName": "AATPService",
          "Password": "${var.creds["AATPServicePassword"]}"
        },
        "AipServiceCreds": {
          "UserName": "${var.creds["AipDomainServiceAccount"]}",
          "Password": "${var.creds["AipDomainServiceAccountPassword"]}"
        }
      }
    }
PROTECTED_SETTINGS
}

#resource "azurerm_virtual_machine_extension" "joindomain" {
#  count = var.compute_instance_count
#  name                 = "joindomain"
#  virtual_machine_id   = element(azurerm_virtual_machine.compute.*.id, count.index)
#  publisher            = "Microsoft.Compute"
#  type                 = "JsonADDomainExtension"
#  type_handler_version = "1.3"
#
#  settings = <<SETTINGS
#      {
#        "Name": "EXAMPLE.COM",
#        "User": "EXAMPLE.COM\\azureuser",
#        "Restart": "true",
#        "Options": "3"
#      }
#    SETTINGS
#
#  protected_settings = <<PROTECTED_SETTINGS
#    {
#      "Password": "F@ncyP@ssw0rd"
#    }
#PROTECTED_SETTINGS
#}


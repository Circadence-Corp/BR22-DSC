data "azurerm_virtual_machine" "vm" {
  for_each            = var.blueprint
  name                = each.value.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_machine_extension" "dsc_dc" {
  name                 = "dsc_dc"
  virtual_machine_id   = data.azurerm_virtual_machine.vm["Dc"].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  timeouts {
    create = "1h"
  }

  settings = <<SETTINGS
        {
            "configuration": {
                "url": "${var.blueprint["Dc"].DscUrl}",
                "script": "${var.blueprint["Dc"].DscScript}",
                "function": "${var.blueprint["Dc"].Function}"
              },
            "configurationArguments": {
              "DomainName": "${var.domain_info["DomainName"]}",
              "UserPrincipalName": "${var.domain_info["UserPrincipalName"]}",
              "NetBiosName": "${var.domain_info["NetBiosName"]}",
              "Branch": "${var.branch}"
            }
        }
    SETTINGS

  protected_settings = jsonencode(var.protected_settings_map[data.azurerm_virtual_machine.vm["Dc"].name])
}

resource "azurerm_virtual_machine_extension" "dsc_client" {
  for_each             = tomap({ for k, v in var.blueprint : k => var.blueprint[k] if k != "Dc" })
  name                 = join("_", ["dsc", each.value.name])
  virtual_machine_id   = data.azurerm_virtual_machine.vm[each.key].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  timeouts {
    create = "1h"
  }

  settings = <<SETTINGS
        {
            "configuration": {
                "url": "${var.blueprint[each.key].DscUrl}",
                "script": "${var.blueprint[each.key].DscScript}",
                "function": "${var.blueprint[each.key].Function}"
              },
            "configurationArguments": {
              "DomainName": "${var.domain_info["DomainName"]}",
              "NetBiosName": "${var.domain_info["NetBiosName"]}",
              "DnsServer": "${var.blueprint["Dc"].private_ip_address}",
              "Branch": "${var.branch}"
            }
        }
    SETTINGS

  protected_settings = jsonencode(var.protected_settings_map[each.value.name])
  depends_on         = [azurerm_virtual_machine_extension.dsc_dc]
}

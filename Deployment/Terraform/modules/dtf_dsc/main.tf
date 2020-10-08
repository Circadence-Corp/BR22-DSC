data "azurerm_virtual_machine" "vm_dc" {
  name = var.blueprint["domain_controller"]
  resource_group_name = var.resource_group_name
}

data "azurerm_virtual_machine" "vm_client" {
  for_each = toset(var.blueprint["domain_client"])
  name = each.value
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_machine_extension" "dsc_dc" {
  name                 = "dsc_dc"
  virtual_machine_id   = data.azurerm_virtual_machine.vm_dc.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  settings = jsonencode(var.dsc_extension_settings["settings"])
  protected_settings = jsonencode(var.dsc_extension_settings["protected_settings"])
  timeouts {
    create = "1h"
  }
}

resource "azurerm_virtual_machine_extension" "dsc_client" {
  for_each = toset(var.blueprint["domain_client"])
  name                 = join("_", ["dsc",each.value])
  virtual_machine_id   = data.azurerm_virtual_machine.vm_client[each.value].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  settings = jsonencode(var.dsc_extension_settings["settings"])
  protected_settings = jsonencode(var.dsc_extension_settings["protected_settings"])

  timeouts {
    create = "1h"
  }

  depends_on = [azurerm_virtual_machine_extension.dsc_dc]
}
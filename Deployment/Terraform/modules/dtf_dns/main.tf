data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "zone" {
  name                = var.domain_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "c2" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.zone.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = ["104.41.2.23"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "turla_dns"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  registration_enabled  = false
}


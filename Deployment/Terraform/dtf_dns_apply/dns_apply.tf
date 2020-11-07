provider "azurerm" {
  features {}
}

module "dns" {
  source               = "../modules/dtf_dns"
  resource_group_name  = "DefendTheFlag"
  virtual_network_name = "vNet-DefendTheFlag"
  domain_name          = "bronerg.tk"
  tags = {
    Description = "ihockett - testing with terraform"
  }
}

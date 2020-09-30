provider "azurerm" {
  features {}
}

module "br22" {
  source                       = "./modules/br22"
  ResourceGroupName            = "ihockett-testing"
  Location                     = "Central US"
  Description                  = "ihockett - testing with terraform"
  builtinAdministratorAccount  = "ContosoAdmin"
  builtinAdministratorPassword = "Password123!@#"
}

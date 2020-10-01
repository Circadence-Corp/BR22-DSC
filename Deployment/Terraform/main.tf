provider "azurerm" {
  subscription_id = "c084b1bc-6711-4832-a64b-f54dc8fea818"
  features {}
}

module "br22" {
  source                       = "./modules/br22"
  resourceGroupName            = "ihockett-testing"
  name                         = "DefendTheFlag-V3"
  location                     = "Central US"
  description                  = "ihockett - testing with terraform"
  builtinAdministratorAccount  = "ContosoAdmin"
  builtinAdministratorPassword = "Password123!@#"
}

provider "azurerm" {
  subscription_id = "c084b1bc-6711-4832-a64b-f54dc8fea818"
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

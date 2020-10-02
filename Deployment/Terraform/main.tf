provider "azurerm" {
  subscription_id = "c084b1bc-6711-4832-a64b-f54dc8fea818"
  features {}
}

module "br22" {
  source                       = "./modules/br22"
  resourceGroupName            = "ihockett-testing"
  name                         = "DefendTheFlag-V3"
  location                     = "Central US"
  subnets_internal             = ["10.0.24.0/24"]
  tags = {
    Description = "ihockett - testing with terraform"
  }

  mgmt_ips = [
    "174.63.122.101",
    "173.175.252.127"
  ]

  dsc_info = {
    DcDscUrl = "https://github.com/Circadence-Corp/BR22-DSC/blob/terraform_rewrite/ihockett/DSC/ProvisionDcDsc.zip?raw=true'"
    DcDscScript = "ProvisionDcDsc.ps1"
    DcFunction = "CreateADForest"
    DomainName = "Contoso.Azure"
    NetBiosName = "CONTOSO"
    UserPrincipalName = "alpineskihouse"
    Branch = "terraform_rewrite/ihockett"
  }

  creds = {
    builtinAdministratorAccount  = "ContosoAdmin"
    builtinAdministratorPassword = "Password123!@#"
    JeffLPassword = "Password$fun"
    SamiraAPassword = "NinjaCat123!@#"
    RonHdPassword = "FightingTiger$"
    LisaVPassword = "HighImpactUser1!"
    AATPServicePassword = "Password123!@#"
    AipDomainServiceAccount = "AipScanner"
    AipDomainServiceAccountPassword = "Somepass1"
  }

  blueprint = {
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

output "all_public_ip_addresses" {
  value = module.br22.public_ips
}
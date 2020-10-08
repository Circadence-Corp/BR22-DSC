provider "azurerm" {
  features {}
}

variable "creds" {
  type        = map
  description = "creds to use in this configuration"

  default = {
    builtinAdministratorAccount = {
      UserName = "ContosoAdmin"
      Password = "Password123!@#"
    }
    JeffL = {
      UserName = "JeffL"
      Password = "Password$fun"
    }
    SamiraA = {
      UserName = "SamiraA"
      Password = "NinjaCat123!@#"
    }
    RonHd = {
      UserName = "RonHd"
      Password = "FightingTiger$"
    }
    LisaV = {
      UserName = "LisaV"
      Password = "HighImpactUser1!"
    }
    AatpService = {
      UserName = "AATPService"
      Password = "Password123!@#"
    }
    AipService = {
      UserName = "AipScanner"
      Password = "Somepass1"
    }
  }
}

variable "branch" {
  type        = string
  description = "The git branch to use (necessary for DSC configs)."
  default     = "terraform_rewrite/ihockett"
}

module "dtf_dsc" {
  source              = "../modules/dtf_dsc"
  resource_group_name = "ihockett-testing"
  branch              = var.branch
  creds               = var.creds

  domain_info = {
    DomainName        = "Contoso.Azure"
    NetBiosName       = "CONTOSO"
    UserPrincipalName = "alpineskihouse"
  }

  blueprint = {
    Dc = {
      vm_name   = "ContosoDc"
      private_ip_address     = "10.0.24.4"
      DscUrl    = "https://github.com/Circadence-Corp/BR22-DSC/blob/${var.branch}/DSC/ProvisionDcDsc.zip?raw=true'"
      DscScript = "ProvisionDcDsc.ps1"
      Function  = "CreateADForest"
      protected_settings = jsonencode(
        {
          configurationArguments = {
            AdminCreds       = var.creds["builtinAdministratorAccount"]
            JeffLCreds       = var.creds["JeffL"]
            SamiraACreds     = var.creds["SamiraA"]
            RonHdCreds       = var.creds["RonHd"]
            LisaVCreds       = var.creds["LisaV"]
            AatpServiceCreds = var.creds["AatpService"]
            AipServiceCreds  = var.creds["AipService"]
          }
        }
      )
    }
    VictimPc = {
      vm_name   = "VictimPc"
      DscUrl    = "https://github.com/Circadence-Corp/BR22-DSC/blob/${var.branch}/DSC/ProvisionVictimPcDsc.zip?raw=true'"
      DscScript = "ProvisionVictimPcDsc.ps1"
      Function  = "SetupVictimPc"
      protected_settings = jsonencode(
        {
          configurationArguments = {
            AdminCred = var.creds["builtinAdministratorAccount"]
            RonHdCred = var.creds["RonHd"]
          }
        }
      )
    }
    AdminPc = {
      vm_name   = "AdminPc"
      DscUrl    = "https://github.com/Circadence-Corp/BR22-DSC/blob/${var.branch}/DSC/ProvisionAdminPcDsc.zip?raw=true'"
      DscScript = "ProvisionAdminPcDsc.ps1"
      Function  = "SetupAdminPc"
      protected_settings = jsonencode(
        {
          configurationArguments = {
            AdminCred      = var.creds["builtinAdministratorAccount"]
            SamiraACred    = var.creds["SamiraA"]
            AipServiceCred = var.creds["AipService"]
          }
        }
      )
    },
    Client01 = {
      vm_name   = "Client01"
      DscUrl    = "https://github.com/Circadence-Corp/BR22-DSC/blob/${var.branch}/DSC/ProvisionClient01.zip?raw=true'"
      DscScript = "ProvisionClient01.ps1"
      Function  = "SetupAipScannerCore"
      protected_settings = jsonencode(
        {
          configurationArguments = {
            AdminCred = var.creds["builtinAdministratorAccount"]
            LisaVCred = var.creds["LisaV"]
          }
        }
      )
    }
  }
}

#output "all_public_ip_addresses" {
#  value = module.dtf_base.public_ips
#}

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
  description = "The git branch to use (necessary for DSC configs and helpful for testing)."
  default     = "dsc_rewrite/ihockett"
}

module "dtf_dsc" {
  source              = "../modules/dtf_dsc"
  resource_group_name = "ihockett-testing"
  branch              = var.branch
  creds               = var.creds

  dsc_extension_settings = {
    settings = {
      configuration = {
        url = "https://github.com/Circadence-Corp/BR22-DSC/blob/${var.branch}/DSC/new/Configuration.zip?raw=true'"
        script = "Configuration.ps1"
        function = "Main"
      }
      configurationArguments = {
        DomainName = "Contoso.Azure"
        UserPrincipalName = "alpineskihouse"
        NetBiosName = "CONTOSO"
        DnsServer = "10.0.24.4"
        Branch = var.branch
      }
    }

    protected_settings = {
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
  }

  blueprint = {
    domain_controller = "ContosoDc"
    domain_client = [
      "VictimPc",
      "AdminPc",
      "Client01"
    ]
  }
}

#output "all_public_ip_addresses" {
#  value = module.dtf_base.public_ips
#}

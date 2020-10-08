provider "azurerm" {
  subscription_id = "c084b1bc-6711-4832-a64b-f54dc8fea818"
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
  }
}

variable "Branch" {
  type        = string
  description = "The git branch to use (necessary for DSC configs)."
  default     = "terraform_rewrite/ihockett"
}

module "dtf_base" {
  source                      = "../modules/dtf_base"
  resource_group_name         = "ihockett-testing"
  name                        = "DefendTheFlag-V3"
  location                    = "Central US"
  subnets_internal            = ["10.0.24.0/24"]
  branch                      = "terraform_rewrite/ihockett"
  builtinAdministratorAccount = var.creds.builtinAdministratorAccount
  tags = {
    Description = "ihockett - testing with terraform"
  }

  mgmt_ips = [
    "174.63.122.101",
    "173.175.252.127"
  ]

  blueprint = {
    Dc = {
      hostname               = "ContosoDc"
      private_ip_address     = "10.0.24.4"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "MicrosoftWindowsServer"
      source_image_offer     = "WindowsServer"
      source_image_sku       = "2016-Datacenter-smalldisk"
      source_image_version   = "latest"
    }
    VictimPc = {
      hostname               = "VictimPc"
      private_ip_address     = "10.0.24.10"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "microsoftwindowsdesktop"
      source_image_offer     = "office-365"
      source_image_sku       = "1903-evd-o365pp"
      source_image_version   = "latest"
    }
    AdminPc = {
      hostname               = "AdminPc"
      private_ip_address     = "10.0.24.11"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "microsoftwindowsdesktop"
      source_image_offer     = "office-365"
      source_image_sku       = "1903-evd-o365pp"
      source_image_version   = "latest"
    },
    Client01 = {
      hostname               = "Client01"
      private_ip_address     = "10.0.24.12"
      size                   = "Standard_D2s_v3"
      source_image_publisher = "microsoftwindowsdesktop"
      source_image_offer     = "office-365"
      source_image_sku       = "1903-evd-o365pp"
      source_image_version   = "latest"
    }
  }
}

output "all_public_ip_addresses" {
  value = module.dtf_base.public_ips
}

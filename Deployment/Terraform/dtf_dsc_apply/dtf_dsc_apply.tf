provider "azurerm" {
  features {}
}

data "local_file" "blueprint" {
  filename = "/Users/ihockett/code/git/circadence/DSRE/BR22-DSC/Deployment/Terraform/blueprint.yaml"
}

variable "branch" {
  type        = string
  description = "The git branch to use (necessary for DSC configs)."
  default     = "terraform_rewrite/ihockett"
}

module "dtf_dsc" {
  source              = "../modules/dtf_dsc"
  resource_group_name = yamldecode(data.local_file.blueprint.content).global.name
  branch              = yamldecode(data.local_file.blueprint.content).global.branch
  creds               = yamldecode(data.local_file.blueprint.content).creds

  domain_info = {
    DomainName        = yamldecode(data.local_file.blueprint.content).global.DomainName
    NetBiosName       = yamldecode(data.local_file.blueprint.content).global.NetBiosName
    UserPrincipalName = yamldecode(data.local_file.blueprint.content).global.UserPrincipalNameSuffix
  }

  blueprint              = yamldecode(data.local_file.blueprint.content).vms
  protected_settings_map = yamldecode(data.local_file.blueprint.content).protected_settings
}

#output "all_public_ip_addresses" {
#  value = module.dtf_base.public_ips
#}

provider "azurerm" {
  features {}
}

data "local_file" "blueprint" {
  filename = "/Users/ihockett/code/git/circadence/DSRE/BR22-DSC/Deployment/Terraform/blueprint.yaml"
}

module "dtf_base" {
  source                      = "../modules/dtf_base"
  resource_group_name         = yamldecode(data.local_file.blueprint.content).global.name
  name                        = yamldecode(data.local_file.blueprint.content).global.name
  location                    = yamldecode(data.local_file.blueprint.content).global.azure_location
  subnets_internal            = yamldecode(data.local_file.blueprint.content).network.subnets_internal
  branch                      = yamldecode(data.local_file.blueprint.content).global.branch
  builtinAdministratorAccount = yamldecode(data.local_file.blueprint.content).creds.builtinAdministratorAccount
  mgmt_ips                    = yamldecode(data.local_file.blueprint.content).network.management_ips
  blueprint                   = yamldecode(data.local_file.blueprint.content).vms
  tags = {
    Description = "ihockett - testing with terraform"
  }
}

output "all_public_ip_addresses" {
  value = module.dtf_base.public_ips
}

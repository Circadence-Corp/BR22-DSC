variable "resourceGroupName" {
  type = string
}

variable "name" {
  type        = string
  description = "Name of this environment e.g. DefendTheFlag."
}

variable "location" {
  type        = string
  description = "The location of the resource group e.g. West Europe"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to include on resources"
}

variable "builtinAdministratorAccount" {
  type    = string
  default = "ContosoAdmin"
}

variable "builtinAdministratorPassword" {
  type    = string
  default = "Password123!@#"
}

variable "subnets_internal" {
  type    = list
  default = ["10.0.24.0/24"]
}

variable "mgmt_ips" {
  type        = list(string)
  description = "IP addresses to allow rdp into the environment"
}

# var.blueprint is our definition of the machines to create, which the resources will iterate over
## EXAMPLE:
#"Dc" = {
#  hostname               = "ContosoDc",
#  private_ip_address     = "10.0.24.4",
#  size                   = "Standard_D2s_v3",
#  source_image_publisher = "MicrosoftWindowsServer",
#  source_image_offer     = "WindowsServer",
#  source_image_sku       = "2016-Datacenter",
#  source_image_version   = "latest"
#},
#"VictimPc" = {
#  hostname               = "VictimPc",
#  private_ip_address     = "10.0.24.10",
#  size                   = "Standard_D2s_v3",
#  source_image_publisher = "MicrosoftWindowsServer",
#  source_image_offer     = "WindowsServer",
#  source_image_sku       = "2016-Datacenter",
#  source_image_version   = "latest"
#}
variable "blueprint" {
  type = map
  description = "Definition of the machines to create. Must include a 'Dc' entry"

  validation {
    condition = contains([for k in keys(var.blueprint) : k if k == "Dc"], "Dc")
    error_message = "The blueprint map must contain one key called 'Dc'."
  }
}

variable "dsc_info" {
  type = map
  description = "DSC-specific configuration information."
}

variable "creds" {
  type = map
  description = "Any credentials used in the configuration."
}

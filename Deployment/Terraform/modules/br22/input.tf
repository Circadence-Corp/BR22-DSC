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

variable "description" {
  type        = string
  description = "A description of what this is. Can be anything. Added as a tag to all resources."
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
}

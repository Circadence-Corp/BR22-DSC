variable "resourceGroupName" {
  type = string
}

variable "location" {
  type        = string
  description = "The location of the resource group e.g. West Europe"
}

variable "description" {
  type        = string
  description = "A description of what this is. Added as a tag to all resources."
}

variable "builtinAdministratorAccount" {
  type    = string
  default = "ContosoAdmin"
}

variable "builtinAdministratorPassword" {
  type    = string
  default = "Password123!@#"
}

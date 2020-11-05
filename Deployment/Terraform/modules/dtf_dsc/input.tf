variable "blueprint" {
  type        = map
  description = "Definition of the machines to create. Must include a 'Dc' entry"

  validation {
    condition     = contains([for k in keys(var.blueprint) : k if k == "Dc"], "Dc")
    error_message = "The blueprint map must contain one key called 'Dc'."
  }

  validation {
    condition     = contains([for i in var.blueprint : contains(keys(i), "name") ? 1 : 2], 2) ? false : true
    error_message = "Each entry the blueprint map must contain one key called 'name'."
  }
}

variable "protected_settings_map" {
  type        = map
  description = "(optional) describe your variable"
}

variable "resource_group_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "domain_info" {
  type        = map
  description = "AD domain information."
}

variable "branch" {
  type        = string
  description = "the git branch to use"
}

variable "creds" {
  type        = map
  description = "map of variables to use"
}

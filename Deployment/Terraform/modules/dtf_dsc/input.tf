variable "resource_group_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "branch" {
  type        = string
  description = "the git branch to use"
}

variable "creds" {
  type        = map
  description = "map of variables to use"
}

variable "blueprint" {
  type        = object({
    domain_controller = string
    domain_client = list(string)
  })
  description = "Machines to be applied DSC configurations, grouped by role."

  validation {
    condition     = contains([for k in keys(var.blueprint) : k if k == "domain_controller"], "domain_controller")
    error_message = "The blueprint map must contain one key called 'domain_controller'."
  }

  validation {
    condition     = contains([for k in keys(var.blueprint) : k if k == "domain_client"], "domain_client")
    error_message = "The blueprint map must contain one key called 'domain_client'."
  }
}

variable "dsc_extension_settings" {
  type = object({
    settings = object({
      configuration = object({
        url = string
        script = string
        function = string
      })
      configurationArguments = object({
        DomainName = string
        UserPrincipalName = string
        NetBiosName = string
        DnsServer = string
        Branch = string
      })
    })
    protected_settings = object({
      configurationArguments = any
    })
  })
  description = "The settings and protected settings for the dsc extension to run."
}
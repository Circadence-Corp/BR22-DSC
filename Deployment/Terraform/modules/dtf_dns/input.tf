variable "resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to include on resources"
}

variable "domain_name" {
  type = string
}

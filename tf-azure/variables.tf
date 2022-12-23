variable "resource_group_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
variable "vnet" {
  type        = map(any)
  description = "creating rg and vnet"
  default = {
    "subnet01" = {
      subnet_address = "10.0.0.0/24"
    }
  }
}
variable "vm" {
  type        = map(any)
  description = "creating vm"
  default = {
    "VMWSRV2016" = {}
  }
}
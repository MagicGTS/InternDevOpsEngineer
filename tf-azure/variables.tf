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
# Windows VM Admin User
variable "windows_admin_username" {
  type        = string
  description = "Windows VM Admin User"
  default     = "tfadmin"
}

# Windows VM Admin Password
variable "windows_admin_password" {
  type        = string
  description = "Windows VM Admin Password"
  default     = "S3cr3ts24"
}
# Input variable: Name of Storage Account
variable "storage_account_name" {
  description = "The name of the storage account. Must be globally unique, length between 3 and 24 characters and contain numbers and lowercase letters only."
  default     = "corpstorage01"
}

# Input variable: Name of Storage container
variable "container_name" {
  description = "The name of the Blob Storage container."
  default     = "backup"
}

variable "resource_group_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
variable "service_plan_name_prefix" {
  default     = "sp"
  description = "Prefix of the App Service Plan name that's combined with a random ID so name is unique in your Azure subscription."
}
variable "vnet" {
  type        = map(any)
  description = "creating rg and vnet"
  default = {
    "frontend" = {
      subnet_address                = "10.0.0.0/24"
      private_endpoint              = true
      enforce_private_link_policies = true
    },
    "backend" = {
      subnet_address                = "10.0.1.0/24"
      private_endpoint              = true
      enforce_private_link_policies = false
    }
  }
}

variable "frontend_port_name" {
  default = "myFrontendPort"
}

variable "frontend_ip_configuration_name" {
  default = "myAGIPConfig"
}

variable "http_setting_name" {
  default = "myHTTPsetting"
}

variable "listener_name" {
  default = "myListener"
}

variable "request_routing_rule_name" {
  default = "myRoutingRule"
}

variable "redirect_configuration_name" {
  default = "myRedirectConfig"
}
variable "private_link_configuration_name" {
  default = "PrivateLinkConfig"
}
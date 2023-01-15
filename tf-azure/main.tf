resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}
resource "random_pet" "sp_name" {
  prefix = var.service_plan_name_prefix
}
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}
resource "azurerm_virtual_network" "vnet" {
  name                = "TFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "TFSubnet" {
  for_each                                  = var.vnet
  name                                      = each.key
  address_prefixes                          = [each.value.subnet_address]
  virtual_network_name                      = "TFVnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  private_endpoint_network_policies_enabled = true
}
# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "network" {
  name                = "myAppGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.TFSubnet["frontend"].id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.my_terraform_public_ip.id
  }

  backend_address_pool {
    name = azurerm_subnet.TFSubnet["backend"].name
  }

  backend_http_settings {
    name                                = var.http_setting_name
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "probe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }
  probe {
    name     = "probe"
    protocol = "Http"
    path     = "/"
    #host     = "127.0.0.1"
    host = "${azurerm_linux_web_app.webapp.name}.azurewebsites.net"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
  }
  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = azurerm_subnet.TFSubnet["backend"].name
    backend_http_settings_name = var.http_setting_name
    priority                   = 100
  }
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "webapp-asp-${random_pet.sp_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-${random_pet.sp_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appserviceplan.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      node_version = "16-lts"
    }
  }
}
resource "azurerm_private_endpoint" "example" {
  name                = "${azurerm_linux_web_app.webapp.name}-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.TFSubnet["backend"].id


  private_service_connection {
    name                           = "${azurerm_linux_web_app.webapp.name}-privateconnection"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# private DNS
resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
}

#private DNS Link
resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "${azurerm_linux_web_app.webapp.name}-dnslink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id                 = azurerm_linux_web_app.webapp.id
  repo_url               = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
  branch                 = "main"
  use_manual_integration = true
  use_mercurial          = false
}
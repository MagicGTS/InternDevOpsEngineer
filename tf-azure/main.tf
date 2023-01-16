data "azurerm_client_config" "current" {}
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
  for_each                                      = var.vnet
  name                                          = each.key
  address_prefixes                              = [each.value.subnet_address]
  virtual_network_name                          = "TFVnet"
  resource_group_name                           = azurerm_resource_group.rg.name
  private_endpoint_network_policies_enabled     = each.value.private_endpoint
  private_link_service_network_policies_enabled = each.value.enforce_private_link_policies
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}
# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label = "pip-${random_pet.rg_name.id}"
}
resource "azurerm_user_assigned_identity" "base" {
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = "my-appgw-keyvault"
}


resource "azurerm_key_vault" "kv" {
  name                = "kv${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  access_policy {
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update"
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey"
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Restore",
      "Restore",
      "Set"
    ]
  }

  access_policy {
    object_id = azurerm_user_assigned_identity.base.principal_id
    tenant_id = data.azurerm_client_config.current.tenant_id

    secret_permissions = [
      "Get"
    ]
  }
}


resource "azurerm_key_vault_certificate" "example" {
  name         = "generated-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

resource "azurerm_private_dns_zone" "priv-dns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_private_endpoint" "priv-ep" {
  name                = "app-prevp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.TFSubnet["backend"].id
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.priv-dns.id]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "${random_pet.rg_name.id}-priv-srv-con"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    subresource_names              = ["sites"]
  }
  depends_on = [
    azurerm_private_dns_zone.priv-dns,
    azurerm_subnet.TFSubnet["backend"],
    azurerm_linux_web_app.webapp,
  ]
}
resource "azurerm_application_gateway" "network" {
  name                = "myAppGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  autoscale_configuration {
    max_capacity = 10
    min_capacity = 1
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.TFSubnet["frontend"].id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "${var.frontend_port_name}-ssl"
    port = 443
  }
   frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.my_terraform_public_ip.id
    private_link_configuration_name = var.private_link_configuration_name
  }

  private_link_configuration {
    name = var.private_link_configuration_name

    ip_configuration {
      name                          = "primary"
      subnet_id                     = azurerm_subnet.TFSubnet["backend"].id
      private_ip_address_allocation = "Dynamic"
      primary                       = false
    }
  }
  backend_address_pool {
    name = azurerm_subnet.TFSubnet["backend"].name
    fqdns = ["webapp-${random_pet.sp_name.id}.azurewebsites.net"]
  }

  backend_http_settings {
    name                                = var.http_setting_name
    cookie_based_affinity               = "Disabled"
    host_name  = "webapp-${random_pet.sp_name.id}.azurewebsites.net"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 20
    probe_name                          = "probe"
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  http_listener {
    name                           = "${var.listener_name}-ssl"
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = "${var.frontend_port_name}-ssl"
    protocol                       = "Https"
    ssl_certificate_name           = "app_listener"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.base.id]
  }

  ssl_certificate {
    name                = "app_listener"
    key_vault_secret_id = azurerm_key_vault_certificate.example.secret_id
  }
  probe {
    name     = "probe"
    protocol = "Http"
    path     = "/"
    host                = "webapp-${random_pet.sp_name.id}.azurewebsites.net"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
    match {
      status_code = ["200-399"]
    }
  }
  redirect_configuration {
    include_path         = true
    include_query_string = true
    name                 = var.request_routing_rule_name
    redirect_type        = "Permanent"
    target_listener_name = "${var.listener_name}-ssl"
  }
  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    redirect_configuration_name = var.request_routing_rule_name
    priority                   = 100
  }
  request_routing_rule {
    name                       = "${var.request_routing_rule_name}-ssl"
    rule_type                  = "Basic"
    http_listener_name         = "${var.listener_name}-ssl"
    backend_address_pool_name  = azurerm_subnet.TFSubnet["backend"].name
    backend_http_settings_name = var.http_setting_name
    priority                   = 50
  }
  
  depends_on = [
    azurerm_subnet.TFSubnet["fronted"],
    azurerm_subnet.TFSubnet["backend"],
    azurerm_public_ip.my_terraform_public_ip
  ]
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
  https_only          = false
  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      node_version = "16-lts"
    }
  }
}
resource "azurerm_app_service_custom_hostname_binding" "srv_host_bind" {
  app_service_name    = "webapp-${random_pet.sp_name.id}"
  hostname            = "webapp-${random_pet.sp_name.id}.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_linux_web_app.webapp,
  ]
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
  depends_on = [
    azurerm_private_dns_zone.example,
    azurerm_virtual_network.vnet,
  ]
} 
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id                 = azurerm_linux_web_app.webapp.id
  repo_url               = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
  branch                 = "main"
  use_manual_integration = true
  use_mercurial          = false
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}
resource "random_uuid" "uuid" {
}
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}
resource "azurerm_kubernetes_cluster" "aks" {
  automatic_channel_upgrade = "patch"
  dns_prefix                = random_pet.rg_name.id
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  name                      = random_pet.rg_name.id
  default_node_pool {
    enable_auto_scaling = true
    max_count           = 5
    min_count           = 1
    name                = "agentpool"
    vm_size             = "Standard_B2s"
    zones               = ["1", "2", "3"]
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_kubernetes_cluster_node_pool" "aks_np" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  max_count             = 5
  min_count             = 1
  mode                  = "System"
  name                  = "agentpool"
  vm_size               = "Standard_B2s"
  zones                 = ["1", "2", "3"]
  depends_on = [
    azurerm_kubernetes_cluster.aks,
  ]
}
resource "azurerm_monitor_action_group" "ag" {
  name                = "RecommendedAlertRules-AG-1"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "recalert1"
  email_receiver {
    email_address           = "magicgts@gmail.com"
    name                    = "Email_-EmailAction-"
    use_common_alert_schema = true
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_monitor_metric_alert" "metric_mem" {
  auto_mitigate       = false
  frequency           = "PT5M"
  name                = "Memory Working Set Percentage - ${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "node_memory_working_set_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 80
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_monitor_metric_alert" "metric_cpu" {
  auto_mitigate       = false
  frequency           = "PT5M"
  name                = "CPU Usage Percentage - ${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "node_cpu_usage_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 80
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_application_insights_workbook" "ins_book" {
  data_json           = "{\"version\":\"Notebook/1.0\",\"items\":[{\"type\":10,\"content\":{\"chartId\":\"280253bf-dc62-4025-bc32-b5df2c067c6d\",\"version\":\"MetricsItem/2.0\",\"size\":0,\"chartType\":3,\"resourceType\":\"microsoft.containerservice/managedclusters\",\"metricScope\":0,\"resourceIds\":[\"/subscriptions/be0ac8a4-cf75-414b-b549-95fcf3fa8c21/resourcegroups/aks-test/providers/microsoft.containerservice/managedclusters/interdev\"],\"timeContext\":{\"durationMs\":86400000},\"metrics\":[{\"namespace\":\"insights.container/nodes\",\"metric\":\"insights.container/nodes--cpuUsagePercentage\",\"aggregation\":4},{\"namespace\":\"insights.container/nodes\",\"metric\":\"insights.container/nodes--memoryWorkingSetPercentage\",\"aggregation\":4}],\"gridSettings\":{\"rowLimit\":10000}},\"name\":\"metric - 0\"}],\"isLocked\":true,\"fallbackResourceIds\":[\"Azure Monitor\"]}"
  display_name        = "${random_pet.rg_name.id} - Dash"
  location            = azurerm_resource_group.rg.location
  name                = random_uuid.uuid.result
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

// Databricks workspace
resource "azurerm_databricks_workspace" "main" {
  name                        = var.name_prefix
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = "trial"
  managed_resource_group_name = "data-demo-databricks-solution-dbxinfra"

  custom_parameters {
    storage_account_sku_name = "Standard_LRS"
  }
}


data "databricks_current_user" "me" {
  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

data "azurerm_storage_account" "data_lake" {
  name                = var.storage_account_name
  resource_group_name = var.storage_resource_group_name
}

// Cluster
resource "databricks_cluster" "shared_cluster" {
  cluster_name            = "Shared cluster"
  spark_version           = var.cluster_version_shared
  node_type_id            = var.node_sku
  autotermination_minutes = 10
  data_security_mode      = "USER_ISOLATION"
  num_workers             = 1

  spark_conf = {
    "spark.databricks.io.cache.enabled" : "true"
  }

  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

resource "databricks_cluster" "single_user_cluster" {
  cluster_name            = "Single user cluster"
  spark_version           = var.cluster_version_single
  node_type_id            = var.node_sku
  autotermination_minutes = 10
  data_security_mode      = "SINGLE_USER"
  single_user_name        = data.databricks_current_user.me.user_name

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
    "spark.databricks.io.cache.enabled" : "true"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

# resource "databricks_library" "user_cluster" {
#   cluster_id = databricks_cluster.user_cluster.id
#   maven {
#     coordinates = "com.microsoft.azure:azure-eventhubs-spark_2.11:2.3.17"
#   }
# }

// Authorization to Event Hub for Databricks
resource "azurerm_eventhub_authorization_rule" "pageviewsReceiver" {
  name                = "pageviewsReceiver"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_pageviews
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "pageviewsReceiver" {
  name                = "databricks"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_pageviews
}

resource "azurerm_eventhub_authorization_rule" "starsReceiver" {
  name                = "starsReceiver"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_stars
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "starsReceiver" {
  name                = "databricks"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_stars
}


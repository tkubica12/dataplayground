// Databricks workspace
resource "azurerm_databricks_workspace" "main" {
  name                = var.name_prefix
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "trial"
}


data "databricks_current_user" "me" {
  depends_on = [
    azurerm_databricks_workspace.main
  ]
}
data "databricks_spark_version" "latest" {
  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

data "azurerm_storage_account" "data_lake" {
  name                = var.storage_account_name
  resource_group_name = var.storage_resource_group_name
}

// Cluster
resource "databricks_cluster" "user_cluster" {
  cluster_name            = "User cluster"
  spark_version           = data.databricks_spark_version.latest.id
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


// Identity for Data Factory access
resource "azurerm_user_assigned_identity" "databricks_df_access" {
  name                = "datafactory-databrics-access"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "random_uuid" "databricks_df_access" {
}

resource "azurerm_role_assignment" "databricks_df_access" {
  name                 = random_uuid.databricks_df_access.result
  scope                = azurerm_databricks_workspace.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.databricks_df_access.principal_id
}

// Authorization to Event Hub for generators
resource "azurerm_eventhub_authorization_rule" "pageviewsSender" {
  name                = "pageviewsReceiver"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_pageviews
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "pageviewsSender" {
  name                = "databricks"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_pageviews
}

resource "azurerm_eventhub_authorization_rule" "starsSender" {
  name                = "starsReceiver"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_stars
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "starsSender" {
  name                = "databricks"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.eventhub_resource_group_name
  eventhub_name       = var.eventhub_name_stars
}

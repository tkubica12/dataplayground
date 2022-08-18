// Databricks workspace
resource "azurerm_databricks_workspace" "main" {
  name                = var.name_prefix
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"
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
data "databricks_node_type" "mynode" {
  local_disk = true
  category   = "General Purpose"
  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

data "azurerm_storage_account" "data_lake" {
  name                = var.storage_account_name
  resource_group_name = var.storage_resource_group_name
}

// Single node
resource "databricks_cluster" "single_node" {
  cluster_name            = "Single Node"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.mynode.id
  autotermination_minutes = 20

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
    "spark.databricks.repl.allowedLanguages" : "python,sql"
    "spark.databricks.passthrough.enabled" : "true"
    "spark.databricks.io.cache.enabled" : "true"
    "fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" : "${data.azurerm_storage_account.data_lake.primary_access_key}"
    "fs.azure.account.auth.type.${var.storage_account_name}.dfs.core.windows.net" : "SharedKey"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

// Serverless node
resource "databricks_cluster" "serverless" {
  cluster_name            = "Serverless"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.mynode.id
  autotermination_minutes = 10
  num_workers             = 3

  spark_conf = {
    "spark.databricks.cluster.profile" : "Serverless"
    "spark.master" : "local[*]"
    "spark.databricks.repl.allowedLanguages" : "python,sql",
    "spark.databricks.passthrough.enabled" : "true",
    "spark.databricks.pyspark.enableProcessIsolation" : "true"
    "fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" : "${data.azurerm_storage_account.data_lake.primary_access_key}"
    "fs.azure.account.auth.type.${var.storage_account_name}.dfs.core.windows.net" : "SharedKey"
  }

  custom_tags = {
    "ResourceClass" = "Serverless"
  }

  depends_on = [
    azurerm_databricks_workspace.main
  ]
}

// Identity for Data Factory access
resource "azurerm_user_assigned_identity" "databricks_df_access" {
  name                = "databricks_df_access"
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


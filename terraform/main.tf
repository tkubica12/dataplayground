// Resource Group
resource "azurerm_resource_group" "main" {
  name     = "data-demo"
  location = var.location
}

// Generate random prefix
resource "random_string" "random" {
  length  = 12
  special = false
  lower   = true
  upper   = false
  numeric = false
}

// Data Lake and data generation
module "data_lake" {
  source              = "./modules/data_lake"
  name_prefix         = random_string.random.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  keyvault_id         = azurerm_key_vault.main.id
  users_count         = 100000
  vip_users_count     = 50000
  products_count      = 10000
  orders_count        = 100000

  depends_on = [
    azurerm_role_assignment.currentuser-kv
  ]
}

// ETL to Data Lake
module "data_factory" {
  source                     = "./modules/data_factory"
  name_prefix                = random_string.random.result
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  keyvault_id                = azurerm_key_vault.main.id
  keyvault_url               = azurerm_key_vault.main.vault_uri
  datalake_url               = module.data_lake.datalake_url
  datalake_name              = module.data_lake.datalake_name
  datalake_id                = module.data_lake.datalake_id
  databricks_df_access_id    = module.databricks.databricks_df_access_id
  databricks_cluster_id      = module.databricks.databricks_etl_cluster_id
  databricks_domain_id       = module.databricks.databricks_domain_id
  databricks_resource_id     = module.databricks.databricks_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  depends_on = [
    azurerm_role_assignment.currentuser-kv
  ]
}

// Databricks
module "databricks" {
  source                      = "./modules/databricks"
  name_prefix                 = random_string.random.result
  resource_group_name         = azurerm_resource_group.main.name
  resource_group_id           = azurerm_resource_group.main.id
  location                    = azurerm_resource_group.main.location
  storage_account_name        = module.data_lake.datalake_name
  storage_resource_group_name = azurerm_resource_group.main.name
}

// Streaming analytics
module "stream_analytics" {
  source                     = "./modules/stream_analytics"
  name_prefix                = random_string.random.result
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  datalake_url               = module.data_lake.datalake_url
  datalake_name              = module.data_lake.datalake_name
  datalake_id                = module.data_lake.datalake_id
  eventhub_id_pageviews      = module.data_lake.eventhub_id_pageviews
  eventhub_id_stars          = module.data_lake.eventhub_id_stars
  eventhub_name_pageviews    = module.data_lake.eventhub_name_pageviews
  eventhub_name_stars        = module.data_lake.eventhub_name_stars
  eventhub_namespace_name    = module.data_lake.eventhub_namespace_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

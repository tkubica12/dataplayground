// Resource Group
resource "azurerm_resource_group" "main" {
  name     = "data-demo-microsoft-solution"
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
  source              = "../modules/data_lake"
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

// Streaming analytics
module "stream_analytics" {
  count                      = var.enable_stream_analytics ? 1 : 0
  source                     = "../modules/stream_analytics"
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

// Synapse
module "synapse" {
  source              = "../modules/synapse"
  name_prefix         = random_string.random.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  keyvault_id         = azurerm_key_vault.main.id
  keyvault_url        = azurerm_key_vault.main.vault_uri
  datalake_id         = module.data_lake.datalake_id
  datalake_url        = module.data_lake.datalake_url
}

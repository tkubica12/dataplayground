// Resource Group
resource "azurerm_resource_group" "main" {
  name     = "data-demo-databricks-solution"
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
  users_count         = 10000
  vip_users_count     = 5000
  products_count      = 100000
  products_rate       = 3
  orders_count        = 100000
  orders_rate         = 3

  depends_on = [
    azurerm_role_assignment.currentuser-kv
  ]
}

// Databricks
module "databricks" {
  source                       = "../modules/databricks"
  name_prefix                  = random_string.random.result
  resource_group_name          = azurerm_resource_group.main.name
  resource_group_id            = azurerm_resource_group.main.id
  location                     = azurerm_resource_group.main.location
  storage_account_name         = module.data_lake.datalake_name
  storage_resource_group_name  = azurerm_resource_group.main.name
  eventhub_name_pageviews      = module.data_lake.eventhub_name_pageviews
  eventhub_name_stars          = module.data_lake.eventhub_name_stars
  eventhub_namespace_name      = module.data_lake.eventhub_namespace_name
  eventhub_resource_group_name = azurerm_resource_group.main.name
  sql_server_name              = module.data_lake.sql_server_name
  keyvault_id                  = azurerm_key_vault.main.id
  existing_metastore_id        = var.existing_metastore_id

  depends_on = [
    module.data_lake
  ]
}

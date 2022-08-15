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
  users_count         = 5000000
  products_count      = 100000
  orders_count        = 100000000

  depends_on = [
    azurerm_role_assignment.currentuser-kv
  ]
}

// ETL to Data Lake
module "etl" {
  source              = "./modules/etl"
  name_prefix         = random_string.random.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  keyvault_id         = azurerm_key_vault.main.id
  keyvault_url        = azurerm_key_vault.main.vault_uri
  datalake_url        = module.data_lake.datalake_url
  kv-reader_id        = azurerm_user_assigned_identity.kv-reader.id
  storage-writer_id   = module.data_lake.storage-writer_id

  depends_on = [
    azurerm_role_assignment.currentuser-kv
  ]
}

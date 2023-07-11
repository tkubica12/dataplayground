resource "databricks_secret_scope" "azure" {
  name = "azure"
}

data "azurerm_key_vault_secret" "azuresql" { 
  name         = "sqlpassword"
  key_vault_id = var.keyvault_id
}

resource "databricks_secret" "azuresql" {
  key          = "azuresql"
  string_value = data.azurerm_key_vault_secret.azuresql.value
  scope        = databricks_secret_scope.azure.id
}

resource "databricks_secret" "storage_account_name" {
  key          = "storage_account_name"
  string_value = var.storage_account_name
  scope        = databricks_secret_scope.azure.id
}

resource "databricks_secret" "sql_server_name" {
  key          = "sql_server_name"
  string_value = var.sql_server_name
  scope        = databricks_secret_scope.azure.id
}

resource "databricks_secret" "eventhub_namespace_name" {
  key          = "eventhub_namespace_name"
  string_value = var.eventhub_namespace_name
  scope        = databricks_secret_scope.azure.id
}

resource "databricks_secret" "eventhub_pages_key" {
  key          = "eventhub_pages_key"
  string_value = azurerm_eventhub_authorization_rule.pageviewsReceiver.primary_key
  scope        = databricks_secret_scope.azure.id
}

resource "databricks_secret" "eventhub_stars_key" {
  key          = "eventhub_stars_key"
  string_value = azurerm_eventhub_authorization_rule.starsReceiver.primary_key
  scope        = databricks_secret_scope.azure.id
}
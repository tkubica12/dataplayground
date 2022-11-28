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

resource "databricks_secret" "eventhub_namespace_name" {
  key          = "eventhub_namespace_name"
  string_value = var.eventhub_namespace_name
  scope        = databricks_secret_scope.azure.id
}